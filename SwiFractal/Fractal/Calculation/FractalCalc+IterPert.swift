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


extension MPComplex {
    
    /// Convert MPComplex to Cplx
    var asCplx: Cplx {
        return Cplx(self.real.toDouble(), self.imaginary.toDouble())
    }

}

///
/// Serial approximation coefficents for an iteration of the reference orbit
///
struct SACoefficients {
    var a: Cplx         // Coefficient for Δc¹
    var b: Cplx         // Coefficient for Δc²
    var c: Cplx         // Coefficient for Δc³
    let skipIndex: Int  // First valid iteration for SA (0 = SA makes not sense)

    /// Initial SA coefficients
    static let initial = SACoefficients(
        a: Cplx(1.0, 0.0), b: Cplx.zero, c: Cplx.zero, skipIndex: 0
    )
    
    /// Calculate new ΔC
    /// - Parameter deltaC: ΔC of current point
    /// - Returns: New ΔC if skipIndex greater than 0. Otherwise deltaC.
    func getDeltaC(deltaC: Cplx) -> Cplx {
        guard skipIndex > 0 else { return deltaC }
        
        let aDc  = a * deltaC
        let bDc2 = b * deltaC.squared
        let cDc3 = c * deltaC.squared * deltaC

        return aDc + bDc2 + cDc3
    }
}

//
// Extend FractalCalculation by support for Perturbation method
//
extension FractalCalculation {
    
    /// Check for perturbation glitch (ref. Pauldelbrot)
    /// - Parameters:
    ///   - delta: Complex delta
    ///   - Z: Current Z
    /// - Returns: True if glitch detected
    @inline(__always)
    nonisolated static func isGlitch(delta: Cplx, Z: Cplx) -> Bool {
        let magDelta = delta.magnitude
        let magZ = Z.magnitude
        
        // If delta is very small compared to Z, we loose precision
        // in addition (floating point cancellation)
        return magDelta > 0 && magDelta < magZ * 1e-15
    }
    
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
    /// - Parameters:
    ///   - refOrbit: Reference orbit
    ///   - dC: |Δc| of the pixel = min(size.real, size.imaginary) / max(width, height)
    /// - Returns: SA coefficients + skipIndex (0 if SA makes no sense)
    nonisolated static func computeSACoefficients(refOrbit: [Cplx], dC: Double) -> SACoefficients {
        guard refOrbit.count > 1 else { return SACoefficients.initial }
        
        let tolerance: Double = 1e-6    // relative error threshold

        var a = Cplx(1.0, 0.0)
        var b = Cplx.zero
        var c = Cplx.zero

        let dC2 = dC * dC
        let dC3 = dC2 * dC

        for n in 0..<refOrbit.count - 1 {
            let z2 = refOrbit[n] * 2.0

            // A_{n+1} = 2·Z_n·A_n + 1
            let newA: Cplx = z2 * a + 1.0
            // B_{n+1} = 2·Z_n·B_n + A_n²
            let newB: Cplx = z2 * b + a.squared
            // C_{n+1} = 2·Z_n·C_n + 2·A_n·B_n
            let newC: Cplx = z2 * c + a * b * 2.0

            // Contribution of terms for typical |Δc|:
            // |A·Δc| vs |B·Δc²| vs |C·Δc³|
            let aContrib = newA.length * dC
            let bContrib = newB.length * dC2
            let cContrib = newC.length * dC3
            
            // SA collapses if higher terms are getting big
            let aContribTolerance = tolerance * aContrib
            if bContrib > aContribTolerance || cContrib > aContribTolerance {
                // n is the last valid skip index
                return SACoefficients(a: a, b: b, c: c, skipIndex: n)
            }

            a = newA
            b = newB
            c = newC
        }

        // SA is valid for full reference orbit
        return SACoefficients(a: a, b: b, c: c, skipIndex: refOrbit.count - 1)
    }
    
    /// Calculate point of Mandelbrot set using perturbation algorithm
    /// - Parameters:
    ///   - dC: Delta C to reference Point
    ///   - refOrbit: Reference orbit
    ///   - sa: Series approximation coefficients
    ///   - P: Dynamic calculation parameters
    /// - Returns: Mandelbrot result
    nonisolated static func calculatePointZ2PT(deltaC: Cplx, refOrbit: [Cplx],
                                   sa: SACoefficients, P: DynamicParameters<PT>) -> MandelbrotResult
    {
        let maxRefIter = refOrbit.count - 1 // Length of reference orbit
        var refIndex: Int = 0               // Index to reference orbit
        
        var stripeAvg: Double = 0.0         // Stripe average value
        var stripet: Double = 0.0           // Current stripe value
        
        var Z: Cplx = .zero                 // Start of iteration: Z = 0
        var dZ: Cplx = .zero
        var ndZ: Double = 0.0
        var nZ: Double = 0.0                // Norm of Z: Z.imaginary * Z.imaginary + Z.real * Z.real
        var Z1: Cplx = Cplx(10.0)           // Old value of Z for fast orbit detection
        
        var period: Int = 0                 // Period counter for fast orbit detection
        var D: Cplx = .zero                 // 1st derivation of Z
       
        // Create array for storing orbits
        var orbits: [Cplx] = [.zero]
        orbits.reserveCapacity(P.limits.orbitLength)

        let dC = sa.getDeltaC(deltaC: deltaC)

        for i in sa.skipIndex...P.limits.iterations {
            // Derivation D of old Z
            D = (D + D) * Z + 1.0

            // Iteration step
            dZ = (2.0 * refOrbit[refIndex] + dZ) * dZ + dC
            refIndex += 1
            Z = refOrbit[refIndex] + dZ
            
            // Check for glitch
            if isGlitch(delta: dZ, Z: Z) {
                return MandelbrotResult(smoothIter: Double(i), flags: .error)
            }
            
            if P.bStripes {
                // Double precision is sufficient
                stripet = (sin(Double(P.stripes) * Z.toCplx().arg) + 1) * 0.5
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
                // distance = (absZ * logAbsZ * 2) / |D|, calculated in RT to avoid over-/underflow
                // We return the logarithm of the distance because:
                // - Logarithm must be calculated with arbitrary precision
                // - MandelbrotResult supports only Double values
                // - We need the logarithm of the distance for color mapping
                let dLength = D.length
                var logPixelDist: Double = .greatestFiniteMagnitude
                var filamentStrength: Double = 0.0
                if dLength > 0 {
                    let absZ = sqrt(nZ)     // abs(Z), only needed for the distance estimate
                    let distance = absZ * logAbsZ * 2.0 / dLength
                    logPixelDist = log(distance) - P.logPixel
                    
                    // Calculate filament: dimensionless ratio in RT, the rest in Double
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
                    stripeAvg = biasCorrect(previousAvg: stripeAvg, smooth: P.stripeSig, iter: i, smoothIter: frac)
                }
                
                // Calculate normal
                // Normal: normalize in RT BEFORE converting to Double (otherwise underflow at deep zoom)
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
                    flags: .bailout
                )
            }
            
            // Calculate orbits
            if P.colorizeInside == .orbits {
                // Long periodicity check
                if let index = findOrbit(orbit: orbits, Z: Z, tolerance: (P.t1, P.t2)) {
                    return MandelbrotResult(smoothIter: Double(i), distance: Double(orbits.count - index), flags: .inside)
                }
                orbits.append(Z)
                if orbits.count == P.limits.orbitLength { orbits.removeFirst() }
            }
            else if P.colorizeInside == .fastOrbits {
                // Simplified periodicity check
                if Z.almostEqual(to: Z1, tolerance: P.t3) {
                    return MandelbrotResult(smoothIter: Double(i), distance: Double(period), flags: .inside)
                }
                
                period += 1
                if period > P.limits.orbitLength {
                    period = 0
                    Z1 = Z
                }
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
        
        return .defaultValue
    }
    
    
}
