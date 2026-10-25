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
    
    /// Find orbit
    /// - Parameters:
    ///   - orbit: Array with Z values
    ///   - Z: Current Z value
    ///   - tolerance: Tuple of two tolerance values
    /// - Returns: Orbit length or -1 if no orbit found
    @inline(__always)
    nonisolated static func findOrbit(orbit: [CT], Z: CT, tolerance: (t1: RT, t2: RT)) -> Int {
        guard orbit.lastIndex(where: { $0.almostEqual(to: Z, tolerance: tolerance.t1) }) != nil else {
            return -1
        }
        guard let idx = orbit.lastIndex(where: { $0.almostEqual(to: Z, tolerance: tolerance.t2) }) else {
            return -1
        }
        return orbit.count - idx
    }
        
    /// Calculate point of Mandelbrot or Julia set
    /// - Parameters:
    ///   - Z0: Initial value of Z
    ///   - C: Initial value of C
    ///   - P: Dynamic parameter structure
    /// - Returns: Mandelbrot result
    nonisolated static func calculatePointZ2(Z0: CT, C: CT, P: DynamicParameters<PT>) -> MandelbrotResult {
        
        let ctZero: CT = .zero(precision: P.dimensions.precision.bits)
        
        var stripeAvg: Double = 0.0     // Stripe average value
        var stripet: Double = 0.0       // Current stripe value
        
        var Z = Z0                      // Start of iteration
        var Z1 = CT(10.0, 10.0)
        var nZ: Double = 0.0            // Squared norm of Z: Z.imaginary * Z.imaginary + Z.real * Z.real
        var absZ: Double = 0.0          // abs(Z) = sqrt(nZ)
        
        var period: Int = 0             // Period counter for fast orbit detection
        var D = ctZero                  // 1st derivation of Z: D = 0
        
        // Tolerance values for full orbit detection
        let t1 = RT(P.limits.orbitDelta1, precision: P.precision)                           // Lower tolerance
        let t2 = RT(P.limits.orbitDelta1 * P.limits.orbitDeltaF, precision: P.precision)    // Upper tolerance
        
        // Tolerance value for fast orbit detection (no coloring)
        let t3 = RT(P.limits.orbitDelta3, precision: P.precision)
        
        // Create array for storing orbits
        var orbits: [CT] = [Z0]
        orbits.reserveCapacity(P.limits.orbitLength)
        
        var dScratch = CT.makeScratch(precision: P.precision)   // Scratch value for derivation
        var zScratch = CT.makeScratch(precision: P.precision)   // Scratch value for iteration
        
        for i in 0...P.limits.iterations {
            
            // Derivation D of Z
            // D = D * 2.0 * Z + 1.0
            D.formDerivativeStep(z: Z, scratch: &dScratch)
            
            // Iteration formula
            // Z = Z * Z + C
            Z.formSquareAdd(C, scratch: &zScratch)
            
            if P.bStripes {
                // stripet = (sin(Double(P.MP.stripes) * Z.arg) + 1.0) * 0.5
                stripet = (sin(Double(P.stripes) * Z.arg.toDouble()) + 1) * 0.5
            }
            
            nZ = Z.lengthSquared.toDouble()
            
            if nZ > P.limits.bailout {
                absZ = sqrt(nZ)           // aZ = abs(Z)
                let logAbsZ = log(absZ)   // logaZ = log(abs(Z))
                
                // logRatio = 2 * log(aZ) / log(bailout)
                // Using precalculated values
                // div_2_logBailout = 2 / log(bailout)
                // let logRatio = logAbsZ * P.div_2_logBailout
                //let logRatio = 2.0 * logaZ / log(P.MP.bailout)
                
                // Calculate smooth iteration value for smooth coloring
                // This value must be added to the iteration count.
                // smoothIter = 1.0 - log(logRatio) * _NC.RLOG2
                let smoothIter = -log(logAbsZ / P.limits.logBailout) * _NC.RLOG2
                
                // Exterior distance estimation
                //
                // distance = (absZ * logAbsZ * 2) / D.length
                // The numerator (absZ * logAbsZ * 2) is a Double value .
                // The denominator D.length must be a RT value.
                // Division is done in RT to prevent overflow and underflow.
                let rtDistance: RT = RT(absZ * logAbsZ * 2.0, precision: P.precision) / D.length
                let logPixelDist: Double = RT.log(rtDistance).toDouble() - P.logPixel
                
                // Calculate filament
                //
                // Dimensionless ratio is calculated in RT,
                // everything else can be calculated with Double precision
                let ratio: Double = (rtDistance * P.invDistThreshold).toDouble()
                let t = min(max(1.5 - ratio, 0.0), 1.0)      // 1 for ratio <= 0.5, 0 for ratio >= 1.5
                let filamentStrength = t * t * (3.0 - 2.0 * t)
                
                // Calculate potential
                //
                // Potential = log(abs(Z)) / 2^N
                // P.potential[N] already contains 1/2^N
                //
                // Alternative calculation:
                //
                // let lognZ = log(nZ) * 0.5
                // Potential = log(lognZ / _NC.LOG2) / _NC.LOG2
                let potential = logAbsZ * P.potential[i]
                
                // Calculate stripes
                if P.bStripes {
                    // Exponential moving average
                    // stripeAvg = stripeAvg * (1.0 + smoothIter * (P.MP.stripeSig - 1.0))
                    //             + stripet * smoothIter * (1.0 - P.MP.stripeSig)
                    stripeAvg = expMovAvg(previousAvg: stripeAvg, smooth: P.stripeSig, newValue: stripet, smoothIter: smoothIter)
                    
                    // BIAS correction
                    // stripeAvg = stripeAvg /
                    //             (1 - pow(P.colorParameters.stripeSig, Double(i))
                    //             * (1 + smoothIter * (P.colorParameters.stripeSig - 1)))
                    stripeAvg = biasCorrect(previousAvg: stripeAvg, smooth: P.stripeSig, iter: i, smoothIter: smoothIter)
                }
                
                // Calculate normal
                let normal = Z/D
                
                // Return iteration result. Double values only
                return MandelbrotResult(
                    smoothIter: smoothIter + Double(i),
                    nZ: nZ,
                    normalReal: normal.real.toDouble(), normalImag: normal.imaginary.toDouble(),
                    distance: logPixelDist,
                    potential: potential,
                    stripeAvg: stripeAvg,
                    filament: filamentStrength,
                    flags: .bailout
                )
            }
            
            // Calculate orbits
            if P.colorizeInside == .orbits {
                var idx: Int = -1
                for n in stride(from: orbits.count-1, through: 0, by: -1) {
                    let diff = Z - orbits[n]
                    if diff.real * diff.real + diff.imaginary * diff.imaginary < t1 {
                        idx = n
                        break
                    }
                }
                if idx > -1 {
                    for n in stride(from: orbits.count-1, through: 0, by: -1) {
                        let diff = Z - orbits[n]
                        if diff.real * diff.real + diff.imaginary * diff.imaginary < t2 {
                            return MandelbrotResult(
                                smoothIter: Double(i), distance: Double(i - n), flags: .inside)
                        }
                    }
                }
                /*
                let orbitLength = findOrbit(orbit: orbits, Z: Z, tolerance: (t1, t2))
                if orbitLength > -1 {
                    result.flags = .inside
                    result.smoothIter = smoothIter + Double(i)
                    result.distance = Double(orbitLength)
                    return result
                }
                 */
                orbits.append(Z)
                if orbits.count == P.limits.orbitLength { orbits.removeFirst() }
            }
            else if P.colorizeInside == .fastOrbits {
                // Simplified periodicity check
                if Z.almostEqual(to: Z1, tolerance: t3) {
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
                // stripeAvg = expMovAvg(previousAvg: stripeAvg, smooth: P.MP.stripeSig, newValue: stripet)
                stripeAvg = stripeAvg * P.stripeSig + stripet * (1 - P.stripeSig)
            }
        }
        
        if P.colorizeInside == .distance {
            return interiorDistance(C: C, Zn: Z, P: P)
        }
        
        return .defaultValue
    }
    
}

