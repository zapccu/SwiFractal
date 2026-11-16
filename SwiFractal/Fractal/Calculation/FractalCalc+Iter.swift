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
        
        var stripeAvg: Double = 0.0                       // Stripe average value
        var stripet: Double = 0.0                         // Current stripe value
        
        var Z = Z0                                        // Start of iteration
        var D = D0                                        // 1st derivation of Z. D0: 0 for Mandelbrot, 1 for Julia
        var Z1 = CT(10.0, 10.0, precision: P.precision)   // Old Z for fast orbit detection
        var nZ: Double = 0.0                              // Squared norm of Z: Z.imaginary * Z.imaginary + Z.real * Z.real
        
        var period: Int = 0                               // Period counter for fast orbit detection
        
        let isJulia = P.initial.kind == .julia            // Flag for Julia set
        
        // Period detectors (only the one matching colorizeInside is used)
        var orbitBuffer = OrbitBuffer(Z0: Z0, capacity: P.limits.orbitLength)  // Ring buffer
        var brent = BrentState(Z0: Z0)                                         // Brent
        
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
                    
                    // Calculate filament
                    // Calculate dimensionless ratio in RT, the rest in Double
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
            
            // Period detection for the inside of the set
            switch P.colorizeInside {
            case .orbits:
                // Ring buffer: fast for small periods
                if let cycle = orbitBuffer.detect(i: i, Z: Z, t1: P.limits.t1, verify: {
                    verifyCycle(Z: Z, C: C, candidate: $0, P: P)
                }) {
                    return insideResult(i: i, Z: Z, cycle: cycle, P: P)
                }
                
            case .brentOrbits, .brentLambda, .distance:
                // Brent: any period
                if let cycle = brent.detect(i: i, Z: Z, t1: P.limits.t1, verify: {
                    verifyCycle(Z: Z, C: C, candidate: $0, P: P)
                }) {
                    return insideResult(i: i, Z: Z, cycle: cycle, P: P)
                }
                
            case .fastOrbits:
                // Simplified periodicity check
                let diff = Z - Z1
                if diff.lengthSquared.toDouble() < P.limits.t3 {
                    return MandelbrotResult(smoothIter: Double(i), distance: Double(period), flags: .inside)
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
                // stripeAvg = expMovAvg(previousAvg: stripeAvg, smooth: P.MP.stripeSig, newValue: stripet)
                stripeAvg = stripeAvg * P.stripeSig + stripet * (1 - P.stripeSig)
            }
        }
        
        // Iteration limit reached without bailout and without detected cycle.
        // Fallback for slowly converging points near the boundary.
        switch P.colorizeInside {
        case .orbits, .brentOrbits, .brentLambda, .distance:
            if let cycle = findCycleAfterIteration(Zn: Z, C: C, P: P) {
                return insideResult(i: P.limits.iterations, Z: Z, cycle: cycle, P: P)
            }
        default:
            break
        }
        
        return .defaultValue
    }
    
}
