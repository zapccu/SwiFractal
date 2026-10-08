//
//  Blending.swift
//  SwiFractal
//
//  Created by Dirk Braner on 10.04.26.
//

import Foundation

///
/// Blending
///
enum EnumBlendingMode: Int, CaseIterable, Equatable {
    
    case none
    case hardLight
    case softLight
    case multiply
    case overlay
    
    /// Blending
    /// - Parameters:
    ///   - base: base layer (a)
    ///   - top:  top layer (b)
    ///   - correction: correction factor for overlay (gamma) and multiply (exposure) blending
    /// - Returns: Blended base value
    func blend(base: Float, top: Float, correction: Float = 1.0) -> Float {
        switch self {
        case .none:
            return base
            
        case .hardLight:
            return top < 0.5
                ? 2 * base * top
                : 1 - 2 * (1 - base) * (1 - top)

        case .softLight:
            let g = base <= 0.25
                ? ((16 * base - 12) * base + 4) * base
                : sqrt(base)
            return top <= 0.5
                ? base - (1 - 2 * top) * base * (1 - base)
                : base + (2 * top - 1) * (g - base)

        case .multiply:
            let lit = base * top * correction
            return lit / (1.0 + lit)        // Tonemapping. Simple Reinhard method

        // overlay = hardLight with gamma correction
        case .overlay:
            let hardLightResult = top < 0.5
                ? 2 * base * top
                : 1 - 2 * (1 - base) * (1 - top)
            return hardLightResult * correction + base * (1 - correction)
        }
    }
    
    /// Blending
    /// - Parameters:
    ///   - base: base layer (a)
    ///   - top: top layer (b)
    ///   - correction: correction factor for overlay (gamma) and multiply (exposure) blending
    /// - Returns: Blended base value
    @inline(__always)
    func blend(base: SIMD3<Float>, top: Float, correction: Float = 1.0) -> SIMD3<Float> {
        return SIMD3<Float>(
            blend(base: base.x, top: top, correction: correction),
            blend(base: base.y, top: top, correction: correction),
            blend(base: base.z, top: top, correction: correction)
        )
    }

}

typealias BlendingMode = Options<EnumBlendingMode>

