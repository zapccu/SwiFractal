//
//  RenderPrecisionStrategy.swift
//  SwiFractal
//
//  Created by Dirk Braner on 22.07.26.
//

import Foundation
import SwiftMPx


//
// Render precision strategy
//
// Required precision for a view of width/height `size` and `r` pixels (larger side):
//
//   bits = |exponent(size)| + ceil(log2(r)) + safetyBits
//
// - .double:        bits <= 53, Double is sufficient for absolute coordinates
// - .perturbation:  reference orbit in MPFloat, iteration of the deltas in Double.
//                   The deltas only need the exponent range of Double, not its mantissa:
//                   the smallest delta (pixel distance) must be a normal Double value.
// - .arbitrary:     the pixel distance is out of Double's exponent range, all calculations in MPFloat
//
// Independent of the strategy, Metal (Metal64 double-float) can be used for absolute coordinates
// as long as bits <= metal64Bits (hi + lo float mantissa = 2 x 24 bits).
//
enum RenderPrecisionStrategy: String, Codable, Equatable {
    
    case double = "double"              // Double only
    case perturbation = "perturbation"  // MPFloat for reference points, Double for iteration
    case arbitrary = "arbitrary"        // MPFloat only
    
    /// Number of mantissa bits of Metal64 f64 (float2 hi + lo)
    static let metal64Bits = 48
    
    /// Number of mantissa bits of Double
    static let doubleBits = 53
    
    /// Calculate number of bits required for the pixel distance relative to the fractal size
    /// - Parameters:
    ///   - resolution: Image resolution in pixel (without oversampling)
    ///   - size: Smaller side of the fractal area
    ///   - safetyBits: Additional bits
    /// - Returns: Required number of bits
    static func requiredBits(resolution: CGSize, size: MPFloat, safetyBits: Int = 8) -> Int {
        let r = max(Double(max(resolution.width, resolution.height)), 2.0)
        return abs(size.exponent) + Int(ceil(log2(r))) + safetyBits
    }
    
    /// Get precision required for absolute coordinates
    /// - Parameters:
    ///   - resolution: Image resolution in pixel (without oversampling)
    ///   - size: Smaller side of the fractal area
    ///   - safetyBits: Additional bits
    /// - Returns: Precision (isDbl = true if Double is sufficient)
    static func getPrecision(resolution: CGSize, size: MPFloat, safetyBits: Int = 8) -> MPFloat.Precision {
        let p = requiredBits(resolution: resolution, size: size, safetyBits: safetyBits)
        return MPFloat.Precision(isDbl: p <= doubleBits, bits: p)
    }
    
    /// Get render strategy and precision for absolute coordinates
    /// - Parameters:
    ///   - resolution: Image resolution in pixel (without oversampling)
    ///   - size: Smaller side of the fractal area
    ///   - safetyBits: Additional bits
    /// - Returns: Render strategy and precision
    static func getRenderStrategy(resolution: CGSize, size: MPFloat, safetyBits: Int = 8) -> (RenderPrecisionStrategy, MPFloat.Precision) {
        let precision = getPrecision(resolution: resolution, size: size, safetyBits: safetyBits)
        if precision.isDbl {
            return (.double, precision)
        }
        
        // Perturbation: the smallest delta (pixel distance) must stay within Double's normal range.
        // The pixel distance has the exponent exponent(size) - log2(r), safety bits are added on top.
        let deltaExponentBits = precision.bits     // = |exponent(size)| + log2(r) + safetyBits
        let minDoubleExponent = -Double.leastNormalMagnitude.exponent   // 1022
        return deltaExponentBits <= minDoubleExponent ? (.perturbation, precision) : (.arbitrary, precision)
    }
    
    /// Check if Metal64 (double-float with 48 bit mantissa) is precise enough for absolute coordinates
    /// - Parameters:
    ///   - resolution: Image resolution in pixel (without oversampling)
    ///   - size: Smaller side of the fractal area
    ///   - safetyBits: Additional bits
    static func isMetal64Sufficient(resolution: CGSize, size: MPFloat, safetyBits: Int = 8) -> Bool {
        requiredBits(resolution: resolution, size: size, safetyBits: safetyBits) <= metal64Bits
    }

}
