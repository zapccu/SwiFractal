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
enum BlendingMode<T: BinaryFloatingPoint> {
    
    case hardLight
    case softLight
    case overlay(gamma: T)

    /// Blending
    /// - Parameters:
    ///   - base: base layer (a)
    ///   - top:  top layer (b)
    func blend(base: T, top: T) -> T {
        switch self {
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

        // overlay = hardLight with gamma correction
        case .overlay(let gamma):
            let hardLightResult = top < 0.5
                ? 2 * base * top
                : 1 - 2 * (1 - base) * (1 - top)
            return hardLightResult * gamma + base * (1 - gamma)
        }
    }

}

