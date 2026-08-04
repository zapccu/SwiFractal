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

extension MPComplex {
    
    /// Convert MPComplex to Cplx
    var complex: Cplx {
        return Cplx(self.real.toDouble(), self.imaginary.toDouble())
    }

}

//
// Extend FractalCalculation by support for Perturbation method
//
extension FractalCalculation where PT.RT == Double {
    
    func isGlitch(delta: Cplx, Z: Cplx) -> Bool {
        let magDelta = delta.magnitude
        let magZ = Z.magnitude
        
        // Wenn delta im Vergleich zu Z winzig ist,
        // verlieren wir die Präzision in der Addition (Floating Point Cancellation)
        return magDelta > 0 && magDelta < magZ * 1e-15 
    }
    
    /// Generate reference orbit for perturbation
    /// - Parameters:
    ///   - refPoint: Reference point
    ///   - P: Dynamic calculation parameters
    /// - Returns: Array with reference orbit
    static func generateReferenceOrbit(refPoint: CT, limits: FractalLimits) -> [Cplx] {
        let rtBailout: RT = RT(limits.bailout, precision: refPoint.precision)
        var Z = CT(0.0, 0.0, precision: refPoint.precision)
        
        var refOrbit: [Cplx] = []
        refOrbit.reserveCapacity(limits.iterations + 1)
        
        for _ in 0...limits.iterations {
            refOrbit.append(Z.toCplx())
            
            Z = Z.squared + refPoint
            
            if Z.lengthSquared > rtBailout {
                refOrbit.append(Z.toCplx())
                break
            }
        }
        
        return refOrbit
    }
    
    /// Calculate point of Mandelbrot set
    static func calculatePointZ2PT(dC: Cplx, refOrbit: [Cplx], P: DynamicParameters<PT>) -> MandelbrotResult {
        var result: MandelbrotResult = .defaultValue
        
        let maxRefIter = refOrbit.count - 1
        var refIndex: Int = 0
        
        var distance: Double = 0.0  // Distance of current point to Mandelbrot set
        var potential: Double = 0.0 // Potential of current point
        var stripeAvg: Double = 0.0 // Stripe average value
        var stripet: Double = 0.0   // Current stripe value
        
        var Z = Cplx(0.0)           // Start of iteration: Z = 0
        var dZ = Cplx(0.0)
        var ndZ: Double = 0.0
        var nZ: Double = 0.0        // Norm of Z: Z.imaginary * Z.imaginary + Z.real * Z.real
        var nZ1: Double = 10.0      // Old value of nZ for fast orbit detection
        var aZ: Double = 0.0        // abs(Z) = sqrt(nZ)
        
        var period: Int = 0         // Period counter for fast orbit detection
        var D = Cplx(0.0, 0.0)      // 1st derivation of Z
        var smoothIter: Double = 0  // Smooth iteration counter
        
        var orbits = Array<Cplx>(repeating: Cplx(0.0), count: P.limits.iterations+1)
        
        for i in 0...P.limits.iterations {
            
            dZ = 2.0 * refOrbit[refIndex] * dZ + dZ * dZ + dC
            refIndex += 1
            Z = refOrbit[refIndex] + dZ
            
            if P.bStripes {
                stripet = (sin(Double(P.coloring.stripes) * Z.arg) + 1.0) * 0.5
            }
            
            nZ = Z.lengthSquared
            
            if nZ > P.limits.bailout {
                aZ = sqrt(nZ)           // aZ = abs(Z)
                let logaZ = log(aZ)
                
                // logRatio = 2 * log(aZ) / log(bailout)
                // Using precalculated values
                // logBailout2 = 2 * log(bailout)
                // let logRatio = logaZ * MP.log2Bailout
                
                // Calculate smooth iteration value for smooth coloring
                // This value must be added to the iteration count.
                //
                // 1.0 - log2(0.5 * log(Z) / log(b))
                //
                smoothIter = 1.0 - log2(log(nZ) * P.div_05_logBailout)
                
                // Calculate exterior distance to Mandelbrot set
                // aZ * log(aZ) / abs(D) / 2.0
                distance = 2.0 * (aZ / D.length) * logaZ * P.diag
                
                // Calculate potential
                // pot = log(abs(Z)) / 2^N
                // potf already contains 1/2^N
                //
                // Alternative calculation:
                // let lognZ = log(nZ) * 0.5
                // potential = log(lognZ / _NC.LOG2) / _NC.LOG2
                potential = logaZ * P.potential[Int(i)]
                
                // Calculate stripes
                if P.bStripes {
                    stripeAvg = expMovAvg(previousAvg: stripeAvg, smooth: P.coloring.stripeSig, newValue: stripet, smoothIter: smoothIter)
                    stripeAvg = biasCorrect(previousAvg: stripeAvg, smooth: P.coloring.stripeSig, iter: i, smoothIter: smoothIter)
                }
                
                let normal = Z/D
                return MandelbrotResult(smoothIter: Double(i) + smoothIter, nZ: nZ, normalReal: normal.real, normalImag: normal.imaginary,
                                        distance: distance, potential: potential, stripeAvg: stripeAvg, flags: [.bailout])
            }
            
            // Calculate orbits
            if P.bOrbits {
                // Search for orbits (full periodicity check)
                var idx: Int = -1
                let end: Int = max(-1, i - 100)
                
                for t in [P.limits.orbitDelta1, P.limits.orbitDelta2] {
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
                if abs(nZ - nZ1) < P.limits.orbitDelta3 {
                    break
                }
                else {
                    period += 1
                    if period > P.limits.orbitLength {
                        period = 0
                        nZ1 = nZ
                    }
                }
            }
            
            if P.bStripes {
                // Calculate exponential moving average of stripe value
                stripeAvg = expMovAvg(previousAvg: stripeAvg, smooth: P.coloring.stripeSig, newValue: stripet)
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
