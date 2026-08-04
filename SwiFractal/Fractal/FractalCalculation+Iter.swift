//
//  FractalCalculation+Iter.swift
//  SwiFractal
//
//  Created by Dirk Braner on 31.07.26.
//


import Foundation
import SwiftUI
import SwiftMPx


extension FractalCalculation {
        
    /// Calculate point of Mandelbrot set
    /// - Parameters:
    ///   - CP: Complex point
    ///   - P: Dynamic parameter structure
    /// - Returns: Result structure
    nonisolated static func calculatePointZ2(Z0: CT, C: CT, P: DynamicParameters<PT>) -> MandelbrotResult {
        
        let prec: Int = P.dimensions.precision.bits
        
        var result: MandelbrotResult = .defaultValue
        
        var distance: Double = 0.0      // Distance of current point to Mandelbrot set
        var potential: Double = 0.0     // Potential of current point
        var stripeAvg: Double = 0.0     // Stripe average value
        var stripet: Double = 0.0       // Current stripe value
        
        var Z = Z0                      // Start of iteration: Z = 0
        var nZ: Double = 0.0            // Squared norm of Z: Z.imaginary * Z.imaginary + Z.real * Z.real
        var nZ1: Double = 10.0          // Old value of nZ for fast orbit detection
        var absZ: Double = 0.0          // abs(Z) = sqrt(nZ)
        
        var period: Int = 0             // Period counter for fast orbit detection
        var D = CT.zero                 // 1st derivation of Z: D = 0
        var smoothIter: Double = 0      // Smooth iteration counter

        // Create array for storing orbits
        var orbits = Array<CT>(repeating: CT.zero, count: P.limits.iterations+1)
        
        for i in 0...P.limits.iterations {
            
            // Iteration formula
            Z = Z.squared + C
            
            if P.bStripes {
                // stripet = (sin(Double(P.MP.stripes) * Z.arg) + 1.0) * 0.5
                stripet = (sin(Double(P.coloring.stripes) * Z.arg.toDouble()) + 1) * 0.5
            }
            
            nZ = Z.lengthSquared.toDouble()
            
            if nZ > P.limits.bailout {
                absZ = sqrt(nZ)           // aZ = abs(Z)
                let logAbsZ = log(absZ)   // logaZ = log(abs(Z))
                
                // logRatio = 2 * log(aZ) / log(bailout)
                // Using precalculated values
                // div_2_logBailout = 2 / log(bailout)
                let logRatio = logAbsZ * P.div_2_logBailout
                //let logRatio = 2.0 * logaZ / log(P.MP.bailout)
                
                // Calculate smooth iteration value for smooth coloring
                // This value must be added to the iteration count.
                //
                // 1.0 - log2(0.5 * log(Z) / log(b))
                //
                //smoothIter = 1.0 - log2(log(nZ) / P.logBailout2)
                smoothIter = 1.0 - log(logRatio) * _NC.RLOG2
                
                // Calculate exterior distance to Mandelbrot set
                //
                // Dist = ((aZ * log(aZ)) / abs(D)) * 2.0
                //
                let rtAbsZ: PT.RT = PT.RT(absZ, precision: prec)
                let rtLogAbsZ: PT.RT = PT.RT(logAbsZ, precision: prec)
                let rtDistance = ((rtAbsZ * rtLogAbsZ) / D.length) * 2.0
                let distThreshold = P.dx * 0.5
                distance = (rtDistance * P.diag).toDouble()
                
                // Calculate potential
                //
                // Potential = log(abs(Z)) / 2^N
                // P.potential[N] already contains 1/2^N
                //
                // Alternative calculation:
                //
                // let lognZ = log(nZ) * 0.5
                // Potential = log(lognZ / _NC.LOG2) / _NC.LOG2
                //
                potential = logAbsZ * P.potential[i]
                
                // Calculate stripes
                if P.bStripes {
                    // Exponential moving average
                    // stripeAvg = stripeAvg * (1.0 + smoothIter * (P.MP.stripeSig - 1.0)) + stripet * smoothIter * (1.0 - P.MP.stripeSig)
                    stripeAvg *= (1.0 + smoothIter * (P.coloring.stripeSig - 1.0))
                    stripeAvg += stripet * smoothIter * (1.0 - P.coloring.stripeSig)
                    
                    // BIAS correction
                    stripeAvg = stripeAvg / (1 - pow(P.coloring.stripeSig, Double(i)) * (1 + smoothIter * (P.coloring.stripeSig - 1)))
                }
                
                // Prepare result values
                smoothIter += Double(i)
                let normal = Z/D
                let normalReal = normal.real.toDouble()
                let normalImag = normal.imaginary.toDouble()
                let filamentStrength = PT.RT.interpolateCubic(edge0: distThreshold * 1.5, edge1: distThreshold * 0.5, x: rtDistance)
                
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
                
                for t in [P.limits.orbitDelta1, P.limits.orbitDelta2] {
                    for n in stride(from: i-1, to: end, by: -1) {
                        let d = Z - orbits[n]
                        if d.lengthSquared.toDouble() < t {
                            idx = n
                            break
                        }
                    }
                }
                
                if idx > -1 {
                    // Found orbit, colorize point inside mandelbrot set
                    result.flags = .inside
                    result.smoothIter = Double(idx)
                    return result
                }
                orbits[i] = Z
            }
            else {
                // Simplified periodicity check, no orbit colorization
                if abs(nZ - nZ1) < P.limits.orbitDelta3 {
                    return result
                }
                
                period += 1
                if period > P.limits.orbitLength {
                    period = 0
                    nZ1 = nZ
                }
            }
            
            if P.bStripes {
                // Calculate exponential moving average of stripe value
                // stripeAvg = expMovAvg(previousAvg: stripeAvg, smooth: P.MP.stripeSig, newValue: stripet)
                stripeAvg = stripeAvg * P.coloring.stripeSig + stripet * (1 - P.coloring.stripeSig)
            }
            
            // Derivation D of Z
            // D = D * 2.0 * Z + 1.0
            D = (Z + Z) * D + 1.0
        }
        
        return result
    }
    
}

