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

    static let initial = SACoefficients(
        a: Cplx(1.0, 0.0), b: Cplx.zero, c: Cplx.zero, skipIndex: 0
    )
}

//
// Extend FractalCalculation by support for Perturbation method
//
extension FractalCalculation {
    
    func isGlitch(delta: Cplx, Z: Cplx) -> Bool {
        let magDelta = delta.magnitude
        let magZ = Z.magnitude
        
        // Wenn delta im Vergleich zu Z winzig ist,
        // verlieren wir die Präzision in der Addition (Floating Point Cancellation)
        return magDelta > 0 && magDelta < magZ * 1e-15 
    }
    
    /// Generate reference orbit for perturbation algorithm.
    /// Reference orbit is calculated with arbitrary precision and converted to double precision.
    /// - Parameters:
    ///   - refPoint: Reference point
    ///   - limits: Calculation limits
    /// - Returns: Array of type Cplx with reference orbit
    static func generateReferenceOrbit(refPoint: MPComplex, limits: FractalLimits) -> [Cplx] {
        let apBailout: MPFloat = MPFloat(limits.bailout, precision: refPoint.precision)
        var Z = MPComplex(0.0, 0.0, precision: refPoint.precision)
        
        var refOrbit: [Cplx] = []
        refOrbit.reserveCapacity(limits.iterations + 1)
        
        for _ in 0...limits.iterations {
            refOrbit.append(Z.asCplx)
            
            Z = Z.squared + refPoint
            
            if Z.lengthSquared > apBailout {
                refOrbit.append(Z.asCplx)
                break
            }
        }
        
        return refOrbit
    }
    
    /// Generate reference orbit for perturbation algorithm calculation in Metal.
    /// Reference orbit is calculated in double precision and converted to single precision (SIMD2 Float32).
    /// - Parameters:
    ///   - refPoint: Reference point
    ///   - limits: Calculation limits
    /// - Returns: Array of type Float2 with reference orbit
    static func generateReferenceOrbit(refPoint: Cplx, limits: FractalLimits) -> [Float2] {
        var Z = Cplx.zero
        
        var refOrbit: [Float2] = []
        refOrbit.reserveCapacity(limits.iterations + 1)

        for _ in 0...limits.iterations {
            refOrbit.append(Float2(Float(Z.real), Float(Z.imaginary)))
            
            Z = Z.squared + refPoint
            
            if Z.lengthSquared > limits.bailout {
                refOrbit.append(Float2(Float(Z.real), Float(Z.imaginary)))
                break
            }
        }
        
        return refOrbit
    }
    
    /// Compute series approximation coefficients along reference orbit.
    ///  
    /// Recursion (Taylor development of perturbation formula):
    ///  
    ///   A{n+1} = 2·Z_n·A_n + 1
    ///   B{n+1} = 2·Z_n·B_n + A_n²
    ///   C{n+1} = 2·Z_n·C_n + 2·A_n·B_n
    ///  
    /// Stop recursion when higher terms dominate the error (SA collapses).
    /// 
    /// - Parameters:
    ///   - refOrbit: Reference orbit
    ///   - dC: |Δc| of the pixel = min(size.real, size.imaginary) / max(width, height)
    /// - Returns: SA coefficients + skipIndex (0 if SA makes no sense)
    func computeSACoefficients(refOrbit: [Cplx], dC: Double) -> SACoefficients {
        
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

            // Beitrag der Terme für typisches |Δc|:
            // |A·Δc| vs |B·Δc²| vs |C·Δc³|
            let aContrib = newA.length * dC
            let bContrib = newB.length * dC2
            let cContrib = newC.length * dC3

            // SA collapses if higher terms getting relatively big
            if bContrib > tolerance * aContrib || cContrib > tolerance * aContrib {
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
    static func calculatePointZ2PT(deltaC: Cplx, refOrbit: [Cplx], sa: SACoefficients, P: DynamicParameters<PT>) -> MandelbrotResult {
        var result: MandelbrotResult = .defaultValue
        
        let maxRefIter = refOrbit.count - 1 // Length of reference orbit
        var refIndex: Int = 0               // Index to reference orbit
        
        var distance: Double = 0.0          // Distance of current point to Mandelbrot set
        var potential: Double = 0.0         // Potential of current point
        var stripeAvg: Double = 0.0         // Stripe average value
        var stripet: Double = 0.0           // Current stripe value
        
        var dC = deltaC
        var Z = Cplx(0.0)                   // Start of iteration: Z = 0
        var dZ = Cplx(0.0)
        var ndZ: Double = 0.0
        var nZ: Double = 0.0                // Norm of Z: Z.imaginary * Z.imaginary + Z.real * Z.real
        var nZ1: Double = 10.0              // Old value of nZ for fast orbit detection
        var absZ: Double = 0.0              // abs(Z) = sqrt(nZ)
        
        var period: Int = 0                 // Period counter for fast orbit detection
        var D = Cplx(0.0, 0.0)              // 1st derivation of Z
        var smoothIter: Double = 0          // Smooth iteration counter
       
        let prec = P.fp.dimensions.precision.bits

        var orbits = Array<Cplx>(repeating: Cplx(0.0), count: P.fp.limits.iterations + 1)
        
        if sa.skipIndex > 0 {
            let aDc  = sa.a * deltaC
            let bDc2 = sa.b * deltaC.squared
            let cDc3 = sa.c * deltaC.squared * deltaC

            dC = aDc + bDc2 + cDc3
        }
        
        for i in sa.skipIndex...P.fp.limits.iterations {
            
            dZ = 2.0 * refOrbit[refIndex] * dZ + dZ * dZ + dC
            refIndex += 1
            Z = refOrbit[refIndex] + dZ
            
            if P.bStripes {
                stripet = (sin(Double(P.fp.colorParameters.stripes) * Z.arg) + 1.0) * 0.5
            }
            
            nZ = Z.lengthSquared
            
            if nZ > P.fp.limits.bailout {
                absZ = sqrt(nZ)           // aZ = abs(Z)
                let logAbsZ = log(absZ)
                
                // logRatio = 2 * log(aZ) / log(bailout)
                // Using precalculated values
                // logBailout2 = 2 * log(bailout)
                // let logRatio = logaZ * MP.log2Bailout
                // let logRatio = logAbsZ * P.div_2_logBailout

                // Calculate smooth iteration value for smooth coloring
                // This value must be added to the iteration count.
                // smoothIter = 1.0 - log(logRatio) * _NC.RLOG2
                smoothIter = -log(log(absZ)/P.logBailout) * _NC.RLOG2


                // Calculate exterior distance to Mandelbrot set
                //
                // Dist = ((aZ * log(aZ)) / abs(D)) * 2.0
                //
                let rtAbsZ: RT = RT(absZ, precision: prec)
                let rtLogAbsZ: RT = RT(logAbsZ, precision: prec)
                let rtDistance = ((rtAbsZ * rtLogAbsZ) / D.length) * 2.0
                distance = (rtDistance * P.diag).toDouble()
                
                // Calculate potential
                //
                // Potential = log(abs(Z)) / 2^N
                // P.potential[N] already contains 1/2^N
                //
                potential = logAbsZ * P.potential[i]
                
                // Calculate stripes
                if P.bStripes {
                    stripeAvg = expMovAvg(previousAvg: stripeAvg, smooth: P.fp.colorParameters.stripeSig, newValue: stripet, smoothIter: smoothIter)
                    stripeAvg = biasCorrect(previousAvg: stripeAvg, smooth: P.fp.colorParameters.stripeSig, iter: i, smoothIter: smoothIter)
                }
                
                // Prepare result values
                smoothIter += Double(i)
                let normal = Z/D
                let normalReal = normal.real.toDouble()
                let normalImag = normal.imaginary.toDouble()
                let filamentStrength = RT.interpolateCubic(edge0: P.distThreshold * 1.5, edge1: P.distThreshold * 0.5, x: rtDistance)
                
                // Return iteration result. Double values only
                return MandelbrotResult(
                    smoothIter: smoothIter, nZ: nZ,
                    normalReal: normalReal, normalImag: normalImag,
                    distance: distance, potential: potential,
                    stripeAvg: stripeAvg,
                    filament: max(min(filamentStrength.toDouble(), 1.0), 0.0),
                    flags: .bailout
                )
            }
            
            // Calculate orbits
            if P.bOrbits {
                // Search for orbits (full periodicity check)
                var idx: Int = -1
                let end: Int = max(-1, i - 100)
                
                for t in [P.fp.limits.orbitDelta1, P.fp.limits.orbitDelta2] {
                    for n in stride(from: i-1, to: end, by: -1) {
                        let d = Z - orbits[n]
                        if d.lengthSquared < t {
                            idx = n
                            break
                        }
                    }
                }
                
                if idx > -1 {
                    // Found orbit, colorize point inside mandelbrot set
                    result.flags = [.inside]
                    result.smoothIter = Double(idx)
                    return result
                }
                orbits[i] = Z
            }
            else {
                // Simplified periodicity check, no orbit colorization
                if abs(nZ - nZ1) < P.fp.limits.orbitDelta3 {
                    break
                }
                else {
                    period += 1
                    if period > P.fp.limits.orbitLength {
                        period = 0
                        nZ1 = nZ
                    }
                }
            }
            
            if P.bStripes {
                // Calculate exponential moving average of stripe value
                stripeAvg = expMovAvg(previousAvg: stripeAvg, smooth: P.fp.colorParameters.stripeSig, newValue: stripet)
            }
            
            // If the delta is larger than the reference, or if the reference orbit has already escaped,
            // reset back to the beginning of the SAME reference orbit!
            ndZ = dZ.length
            if nZ < ndZ || refIndex == maxRefIter {
                dZ = Z
                refIndex = 0
            }
                                                                
            // Derivation D of Z
            // D = D * 2.0 * Z + 1.0
            D = (Z + Z) * D + 1.0
        }
        
        return result
    }
    
    
}
