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
    /// - Returns: Orbit index of first matching Z or nil if no orbit found
    @inline(__always)
    nonisolated static func findOrbit<C: ComplexNumber>(orbit: [C], Z: C,
                                                        tolerance: (t1: Double, t2: Double)) -> Int? {
        // t1: are there any orbits?
        guard orbit.lastIndex(where: { ($0 - Z).lengthSquared.toDouble() < tolerance.t1 }) != nil else {
            return nil
        }
        // t2: double check with higher tolerance
        return orbit.lastIndex(where: { ($0 - Z).lengthSquared.toDouble() < tolerance.t2 })
    }
    
    /// Calculate normal. Normalize in RT before converting to Double (otherwise underflow at deep zoom)
    /// - Parameters:
    ///   - Z: Z value
    ///   - D: Derivation of Z
    /// - Returns: Normal als Cplx value
    @inline(__always)
    nonisolated static func normalize<C: ComplexNumber>(Z: C, D: C) -> Cplx {
        let u = Z / D
        let len = u.length
        return len.sign == .plus ? (u / len).toCplx() : .zero
    }

    /// Calculate point of Mandelbrot or Julia set
    /// - Parameters:
    ///   - Z0: Initial value of Z
    ///   - C: Initial value of C
    ///   - D0: Initial value of D
    ///   - P: Dynamic parameter structure
    /// - Returns: Mandelbrot result
    nonisolated static func calculatePointZ2(Z0: CT, C: CT, D0: CT, P: DynamicParameters<PT>) -> MandelbrotResult {
        
        var stripeAvg: Double = 0.0     // Stripe average value
        var stripet: Double = 0.0       // Current stripe value
        
        var Z = Z0                      // Start of iteration
        var D = D0                      // 1st derivation of Z. D0: 0 for Mandelbrot, 1 for Julia
        var Z1 = CT(10.0, 10.0)         // Old Z for fast orbit detection
        var nZ: Double = 0.0            // Squared norm of Z: Z.imaginary * Z.imaginary + Z.real * Z.real
        
        var period: Int = 0             // Period counter for fast orbit detection
        
        let isJulia = P.initial.kind == .julia
        
        // Create array for storing orbits (ring buffer)
        var orbits: [CT] = [Z0]
        orbits.reserveCapacity(P.limits.orbitLength)
        
        // Reusable scratch values for MPComplex. Not used for Double precision
        var dScratch = CT.makeScratch(precision: P.precision)   // Scratch value for derivation
        var zScratch = CT.makeScratch(precision: P.precision)   // Scratch value for iteration
        
        for i in 0...P.limits.iterations {
            
            // Derivation D of old Z
            // D = D * 2.0 * Z + 1.0
            D.derivativeStep(z: Z, isJulia: isJulia, scratch: &dScratch)
            
            // Iteration formula
            // Z = Z * Z + C
            Z.squareAdd(C, scratch: &zScratch)
            
            if P.bStripes {
                // Double precision is sufficient
                stripet = (sin(Double(P.stripes) * Z.toCplx().arg) + 1) * 0.5
            }
            
            nZ = Z.lengthSquared.toDouble()
            
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
                
                // Normalize, exterior distance, filaments
                let dLength: RT = D.length
                var logPixelDist: Double = .greatestFiniteMagnitude
                var filamentStrength: Double = 0.0
                var normal: Cplx = .zero
                if dLength.sign == .plus {
                    // Normalize
                    normal = normalize(Z: Z, D: D)
                    
                    // Calculate exterior distance
                    // distance = (absZ * logAbsZ * 2) / |D|, calculated in RT to avoid over-/underflow
                    // - Logarithm must be calculated with arbitrary precision
                    // - MandelbrotResult supports only Double values
                    // - We need the logarithm of the distance for color mapping
                    let absZ = sqrt(nZ)     // abs(Z), only needed for the distance estimate
                    let rtDistance: RT = RT(absZ * logAbsZ * 2.0, precision: P.precision) / dLength
                    logPixelDist = RT.log(rtDistance).toDouble() - P.logPixel
                    
                    // Calculate filament: dimensionless ratio in RT, the rest in Double
                    let ratio: Double = (rtDistance * P.invDistThreshold).toDouble()
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
                let diff = Z - Z1
                if diff.lengthSquared.toDouble() < P.t3 {
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

