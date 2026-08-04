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
enum RenderPrecisionStrategy: String, Codable, Equatable {
    
    case double = "double"              // Double only
    case perturbation = "perturbation"  // MPFloat for reference points, Double for iteration
    case arbitrary = "arbitrary"        // MPFloat only
    
    /// Detect precision
    /// - Parameters:
    ///   - resolution: Image resolution
    ///   - size: Minimum of new horizontal and vertical fractal size
    ///   - safetyBits: Safety bits. Default = 8
    ///   - maxInc: Maximum number of precision increments by safetyBits. Default = 5
    /// - Returns: Required precision
    static func getPrecision(resolution: CGSize, size: MPFloat, safetyBits: Int = 8, maxInc: Int = 5) -> MPFloat.Precision {
        let r  = Double(max(resolution.width, resolution.height))
        var p  = abs(size.exponent) + Int(ceil(log2(r))) + safetyBits
        for _ in 0..<maxInc {
            MPFloat.Flag.clearAll()
            let _ = MPFloat(size, precision: p) / MPFloat(r, precision: p)
            if !MPFloat.isFlagSet(.underflow) { break }
            p += safetyBits
        }
        return MPFloat.Precision(isDbl: p <= 53, bits: p)
    }
    
    /// Detect precision and render strategy
    ///   - resolution: Image resolution
    ///   - size: Minimum of new horizontal and vertical fractal size
    ///   - safetyBits: Safety bits. Default = 8
    ///   - maxInc: Maximum number of precision increments by safetyBits. Default = 5
    /// - Returns: Tuple of render strategy and required precision
    static func getRenderStrategy(resolution: CGSize, size: MPFloat, safetyBits: Int = 8, maxInc: Int = 5) -> (RenderPrecisionStrategy, MPFloat.Precision) {
        let refPrecision = getPrecision(resolution: resolution, size: size, safetyBits: safetyBits, maxInc: maxInc)
        if refPrecision.isDbl {
            return (.double, refPrecision)
        }
        
        // Calculate relative precision for delta values.
        // Double allows values of 2^(-52)
        let deltaBits = abs(size.exponent) + safetyBits
        return deltaBits <= 53 ? (.perturbation, refPrecision) : (.arbitrary, refPrecision)
    }

}
