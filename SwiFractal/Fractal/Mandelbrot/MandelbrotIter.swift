//
//  MandelbrotIter.swift
//  SwiFractal
//
//  Created by Dirk Braner on 23.02.26.
//
//  Mandelbrot iteration functions
//

import SwiftUI
import Numerics


extension Mandelbrot {
    
    /// Calculate point of Mandelbrot set
    func calculatePointZ2(_ x: Int, _ y: Int) -> RGBAColor {
        guard var DP else { return RGBAColor.black }

        var color = DP.MP.colorMapping.defColor
        
        let C = DP.cplxGrid[y][x]
        
        var distance: Double = 0.0  // Distance of current point to Mandelbrot set
        var potential: Double = 0.0 // Potential of current point
        var stripeAvg: Double = 0.0 // Stripe average value
        var stripet: Double = 0.0   // Current stripe value
        
        var Z = Cplx(0.0)           // Start of iteration: Z = 0
        var nZ: Double = 0.0        // Norm of Z: Z.imaginary * Z.imaginary + Z.real * Z.real
        var nZ1: Double = 10.0      // Old value of nZ for fast orbit detection
        var aZ: Double = 0.0        // abs(Z) = sqrt(nZ)
        
        var period: Int = 0         // Period counter for fast orbit detection
        var D = Cplx(0.0, 0.0)      // 1st derivation of Z
        var smoothIter: Double = 0  // Smooth iteration counter
        var potf: Double = 0.5      // Potential factor 1/2^N
        
        var orbits = Array<Cplx>(repeating: Cplx(0.0), count: DP.MP.iterations+1)
        
        for i in 0...DP.MP.iterations {
            
            Z = Z * Z + C
            
            if DP.bStripes { 
                stripet = (sin(Double(DP.MP.colorMapping.stripes) * Z.arg) + 1.0) * 0.5
            }
            
            nZ = Z.lengthSquared
            
            if nZ > DP.MP.bailout {
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
                smoothIter = 1.0 - log2(log(nZ) / DP.logBailout2)
                
                // Calculate exterior distance to Mandelbrot set
                // aZ * log(aZ) / abs(D) / 2.0
                distance = 2.0 * (aZ / D.length) * logaZ
                
                // Calculate potential
                // pot = log(abs(Z)) / 2^N
                // potf already contains 1/2^N
                //
                // Alternative calculation:
                // let lognZ = log(nZ) * 0.5
                // potential = log(lognZ / _NC.LOG2) / _NC.LOG2
                potential = logaZ * potf
                
                // Calculate stripes
                if DP.bStripes {
                    stripeAvg = expMovAvg(previousAvg: stripeAvg, smooth: DP.MP.colorMapping.stripeSig, newValue: stripet, smoothIter: smoothIter)
                    stripeAvg = biasCorrect(previousAvg: stripeAvg, smooth: DP.MP.colorMapping.stripeSig, iter: i, smoothIter: smoothIter)
                }
                
                // Count iterations for calculation of histogram
                if DP.bHist && i < DP.MP.iterations {
                    DP.iterationCountPerPixel[y][x] = i
                    DP.pixelCountPerIteration[i] += 1
                }
                
                return DP.MP.colorMapping.mapColorValue(Double(i)+smoothIter, DP.MP.iterations, nZ, Z/D, distance * DP.diag, potential, stripeAvg, DP.lightning)
            }
            
            // Calculate orbits
            if DP.bOrbits {
                // Search for orbits (full periodicity check)
                var idx: Int = -1
                let end: Int = max(-1, i - 100)
                
                for t in [DP.MP.orbitDelta1, DP.MP.orbitDelta2] {
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
                    color = RGBAColor(HSB(min(1.0, Float(Double(i-idx) / Double(DP.MP.iterations) * DP.diaScale)), 1.0, 1.0 - Float(i)/Float(DP.MP.iterations)))
                    break
                }
                orbits[i] = Z
            }
            else {
                // Simplified periodicity check, no orbit colorization
                if abs(nZ - nZ1) < DP.MP.orbitDelta3 {
                    orbitCount += 1
                    break
                }
                else {
                    period += 1
                    if period > DP.MP.orbitLength {
                        period = 0
                        nZ1 = nZ
                    }
                }
            }
            
            if DP.bStripes {
                // Calculate exponential moving average of stripe value
                stripeAvg = expMovAvg(previousAvg: stripeAvg, smooth: DP.MP.colorMapping.stripeSig, newValue: stripet)
            }
            
            // Derivation D of Z
            // D = D * 2.0 * Z + 1.0
            D = (Z + Z) * D + 1.0
            
            potf *= 0.5
        }
        
        if DP.bHist { DP.iterationCountPerPixel[y][x] = DP.MP.iterations }
        
        return color
    }
    
}
