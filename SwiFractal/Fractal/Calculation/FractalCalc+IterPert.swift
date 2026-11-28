//
//  FractalCalculation+Pert.swift
//  SwiFractal
//
//  Calculate Mandelbrot set with perturbation algorithm.
//
//  Created by Dirk Braner on 31.07.26.
//


import SwiftUI
import Numerics
import SwiftMPx
import Metal64


///
/// Serial approximation coefficents for an iteration of the reference orbit
///
struct SACoefficients {
    var a: Cplx         // Coefficient for Δc¹
    var b: Cplx         // Coefficient for Δc²
    var c: Cplx         // Coefficient for Δc³
    let skipIndex: Int  // Number of iterations replaced by the series (0 = no SA)

    static let initial = SACoefficients(
        a: Cplx(1.0, 0.0), b: Cplx.zero, c: Cplx.zero, skipIndex: 0
    )
    
    /// Perturbation δz at iteration skipIndex: δz ≈ A·Δc + B·Δc² + C·Δc³
    @inline(__always)
    func deltaZ(deltaC: Cplx) -> Cplx {
        guard skipIndex > 0 else { return .zero }
        let dC2 = deltaC.squared
        return a * deltaC + b * dC2 + c * dC2 * deltaC
    }
    
    /// Derivative dz/dc at iteration skipIndex: d(δz)/dΔc ≈ A + 2·B·Δc + 3·C·Δc²
    @inline(__always)
    func derivative(deltaC: Cplx) -> Cplx {
        guard skipIndex > 0 else { return .zero }
        return a + b * deltaC * 2.0 + c * deltaC.squared * 3.0
    }
}

extension FractalCalculation {
    
    /// Generate reference orbit for perturbation algorithm.
    /// Reference orbit is calculated with arbitrary precision and converted to double precision.
    /// - Parameters:
    ///   - refPoint: Reference point
    ///   - limits: Calculation limits
    /// - Returns: Array of complex values with reference orbit
    nonisolated static func generateReferenceOrbit(refPoint: CT, limits: FractalLimits) -> [Cplx] {
        let bailout: RT = RT(limits.bailout, precision: refPoint.precision)
        var Z: CT = CT(0.0, 0.0, precision: refPoint.precision)
        
        var refOrbit: [Cplx] = []
        refOrbit.reserveCapacity(limits.iterations + 1)
        
        // Reusable scratch values for MPComplex. Not used for Double precision
        var zScratch = CT.makeScratch(precision: refPoint.precision)   // Scratch value for iteration

        for _ in 0...limits.iterations {
            refOrbit.append(Z.toCplx())
            
            Z.squareAdd(refPoint, scratch: &zScratch)
            
            if Z.lengthSquared > bailout {
                refOrbit.append(Z.toCplx())
                break
            }
        }
        
        return refOrbit
    }
    
    /// Compute series approximation coefficients along reference orbit.
    ///  
    /// Recursion (Taylor development of perturbation formula):
    ///  
    ///   A{n+1} = 2·Zn·An + 1\
    ///   B{n+1} = 2·Zn·Bn + An²\
    ///   C{n+1} = 2·Zn·Cn + 2·An·Bn
    ///  
    /// Stop recursion when higher terms dominate the error (SA collapses).
    ///
    /// The series must be valid for every pixel, so the check uses the largest |Δc| of the image
    /// (distance of the farthest image corner from the reference point), not the pixel distance.
    /// The returned coefficients belong to iteration skipIndex: δz_skip ≈ A·Δc + B·Δc² + C·Δc³.
    /// skipIndex is at most refOrbit.count - 2, so at least one iteration step with the
    /// reference orbit remains.
    /// - Parameters:
    ///   - refOrbit: Reference orbit Z_0 ... Z_n
    ///   - maxDeltaC: Largest |Δc| of the image
    /// - Returns: Coefficients and number of skipped iterations
    nonisolated static func computeSACoefficients(refOrbit: [Cplx], maxDeltaC: Double) -> SACoefficients {
        guard refOrbit.count > 2, maxDeltaC > 0 else { return SACoefficients.initial }
        
        let tolerance: Double = 1e-6    // relative error threshold

        var a = Cplx(1.0, 0.0)          // A_1 = 1, B_1 = 0, C_1 = 0 (δz_1 = Δc)
        var b = Cplx.zero
        var c = Cplx.zero

        let dC = maxDeltaC
        let dC2 = dC * dC
        let dC3 = dC2 * dC
        
        let lastIndex = refOrbit.count - 2
        
        for n in 1..<lastIndex {
            let z2 = refOrbit[n] * 2.0

            // A_{n+1} = 2·Z_n·A_n + 1
            let newA: Cplx = z2 * a + 1.0
            // B_{n+1} = 2·Z_n·B_n + A_n²
            let newB: Cplx = z2 * b + a.squared
            // C_{n+1} = 2·Z_n·C_n + 2·A_n·B_n
            let newC: Cplx = z2 * c + a * b * 2.0

            // Contribution of terms for the largest |Δc|:
            // |A·Δc| vs |B·Δc²| vs |C·Δc³|
            let aContrib = newA.length * dC
            let bContrib = newB.length * dC2
            let cContrib = newC.length * dC3
            
            // SA collapses if higher terms are getting big
            let aContribTolerance = tolerance * aContrib
            if bContrib > aContribTolerance || cContrib > aContribTolerance {
                // n is the last valid skip index, a, b, c belong to n
                return SACoefficients(a: a, b: b, c: c, skipIndex: n)
            }

            a = newA
            b = newB
            c = newC
        }

        // SA is valid up to the last usable index of the reference orbit
        return SACoefficients(a: a, b: b, c: c, skipIndex: lastIndex)
    }
    
    nonisolated static func calculatePointZ2PT(deltaC: Cplx, refC: CT, refOrbit: [Cplx],
                                               sa: SACoefficients, P: DynamicParameters<PT>) -> MandelbrotResult
    {
        let maxRefIter = refOrbit.count - 1 // Length of reference orbit

        var stripeAvg: Double = 0.0         // Stripe average value
        var stripet: Double = 0.0           // Current stripe value
        
        // Start values. Without SA: Z = 0, δz = 0, D = 0 at iteration 0.
        // With SA the iteration starts at skipIndex with δz and D from the series.
        let skipIndex = min(sa.skipIndex, P.limits.iterations)
        var refIndex: Int = skipIndex       // Index to reference orbit
        var dZ: Cplx = sa.deltaZ(deltaC: deltaC)
        var D: Cplx = sa.derivative(deltaC: deltaC)    // 1st derivation of Z
        var Z: Cplx = refOrbit[refIndex] + dZ
        var ndZ: Double = 0.0
        var nZ: Double = 0.0                // Norm of Z: Z.imaginary * Z.imaginary + Z.real * Z.real
        var Z1: Cplx = Cplx(10.0)           // Old value of Z for fast orbit detection
        
        var period: Int = 0                 // Period counter for fast orbit detection
        
        // Period detectors (only the one matching colorizeInside is used).
        // Detection on the full Z = refOrbit + dZ in Double; delta alone is not periodic.
        var orbitBuffer = OrbitBuffer(Z0: Z, capacity: P.limits.orbitLength)   // Ring buffer
        var brent = BrentState(Z0: Z, startIter: skipIndex)                     // Brent
        
        // Full C in calculation precision. Needed only for cycle verification (Newton, |λ|,
        // interior distance). In Double all pixels would collapse to the same C at deep zoom.
        let cFull: CT = refC + CT(deltaC.real, deltaC.imaginary, precision: P.precision)
        
        /// Converts the full Z from Double to CT for verification and result
        @inline(__always)
        func toCT(_ z: Cplx) -> CT { CT(z.real, z.imaginary, precision: P.precision) }
        
        for i in skipIndex...P.limits.iterations {
            // Derivation D of old Z
            D = (D + D) * Z + 1.0
            
            // Iteration step
            dZ = (2.0 * refOrbit[refIndex] + dZ) * dZ + deltaC
            refIndex += 1
            Z = refOrbit[refIndex] + dZ
            
            if P.bStripes {
                // Double precision is sufficient
                stripet = (sin(Double(P.stripes) * Z.arg) + 1) * 0.5
            }
            
            nZ = Z.lengthSquared
            
            if nZ > P.limits.bailout {
                let logAbsZ = 0.5 * log(nZ)     // log(abs(Z)) without sqrt
                
                // Calculate smooth iteration value for smooth coloring
                //
                // This value must be added to the iteration count.
                // logRatio = 2 * log(aZ) / log(bailout)
                // smoothIter = -log(logRatio) * _NC.RLOG2
                let smoothIter = -log(logAbsZ / P.limits.logBailout) * _NC.RLOG2
                
                // Exterior distance estimation (logarithm of the distance)
                //
                // distance = (absZ * logAbsZ * 2) / |D|
                // We return the logarithm of the distance because:
                // - MandelbrotResult supports only Double values
                // - We need the logarithm of the distance for color mapping
                let dLength = D.length
                var logPixelDist: Double = .greatestFiniteMagnitude
                var filamentStrength: Double = 0.0
                if dLength > 0 {
                    let absZ = sqrt(nZ)     // abs(Z), only needed for the distance estimate
                    let distance = absZ * logAbsZ * 2.0 / dLength
                    logPixelDist = log(distance) - P.logPixel
                    
                    // Calculate filament: dimensionless ratio
                    let ratio: Double = distance * P.invDistThreshold.asDouble
                    let t = min(max(1.5 - ratio, 0.0), 1.0)      // 1 for ratio <= 0.5, 0 for ratio >= 1.5
                    filamentStrength = t * t * (3.0 - 2.0 * t)
                }
                
                // Calculate stripes
                if P.bStripes {
                    let frac = smoothIter.clamped
                    
                    // Exponential moving average
                    // stripeAvg = stripeAvg * (1.0 + smoothIter * (P.MP.stripeSig - 1.0))
                    //             + stripet * smoothIter * (1.0 - P.MP.stripeSig)
                    stripeAvg = expMovAvg(previousAvg: stripeAvg, smooth: P.stripeSig, newValue: stripet, smoothIter: frac)
                    
                    // BIAS correction
                    // stripeAvg = stripeAvg /
                    //             (1 - pow(P.colorParameters.stripeSig, Double(i))
                    //             * (1 + smoothIter * (P.colorParameters.stripeSig - 1)))
                    stripeAvg = biasCorrect(previousAvg: stripeAvg, smooth: P.stripeSig, iter: i - skipIndex, smoothIter: frac)
                }
                
                // Calculate normal
                var normal: Cplx = .zero
                if dLength > 0 {
                    let u = Z / D
                    let len = u.length
                    if len > 0 {
                        normal = (u / len)
                    }
                }
                
                // Return iteration result. Double values only
                return MandelbrotResult(
                    smoothIter: smoothIter + Double(i),
                    nZ: nZ,
                    normalReal: normal.real, normalImag: normal.imaginary,
                    distance: logPixelDist,
                    stripeAvg: stripeAvg,
                    filament: filamentStrength,
                    flags: [.bailout]
                )
            }
            
            // Period detection for the inside of the set.
            // Candidate detection in Double, verification in CT with the full C.
            switch P.colorizeInside {
            case .orbits:
                // Ring buffer: fast for small periods
                if let cycle = orbitBuffer.detect(i: i, Z: Z, t1: P.limits.t1, verify: {
                    verifyCycle(Z: toCT(Z), C: cFull, candidate: $0, P: P)
                }) {
                    return insideResult(i: i, Z: toCT(Z), cycle: cycle, P: P)
                }
                
            case .brentOrbits, .brentLambda, .distance:
                // Brent: any period
                if let cycle = brent.detect(i: i, Z: Z, t1: P.limits.t1, verify: {
                    verifyCycle(Z: toCT(Z), C: cFull, candidate: $0, P: P)
                }) {
                    return insideResult(i: i, Z: toCT(Z), cycle: cycle, P: P)
                }
                
            case .fastOrbits:
                // Simplified periodicity check
                let diff = Z - Z1
                if diff.lengthSquared < P.limits.t3 {
                    return MandelbrotResult(smoothIter: Double(i), distance: Double(period), flags: [.inside])
                }
                period += 1
                if period > P.limits.orbitLength {
                    period = 0
                    Z1 = Z
                }
                
            default:
                break
            }
            
            if P.bStripes {
                // Calculate exponential moving average of stripe value
                stripeAvg = expMovAvg(previousAvg: stripeAvg, smooth: P.stripeSig, newValue: stripet)
            }
            
            // If the delta is larger than the reference, or if the reference orbit has already escaped,
            // reset back to the beginning of the SAME reference orbit!
            ndZ = dZ.lengthSquared
            if nZ < ndZ || refIndex == maxRefIter {
                dZ = Z
                refIndex = 0
            }
        }
        
        // Iteration limit reached without bailout and without detected cycle.
        // Fallback for slowly converging points near the boundary (in CT with the full C).
        switch P.colorizeInside {
        case .orbits, .brentOrbits, .brentLambda, .distance:
            let zCT = toCT(Z)
            if let cycle = findCycleAfterIteration(Zn: zCT, C: cFull, P: P) {
                return insideResult(i: P.limits.iterations, Z: zCT, cycle: cycle, P: P)
            }
        default:
            break
        }
        
        return .defaultValue
    }
    
}
