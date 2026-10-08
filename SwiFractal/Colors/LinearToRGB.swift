//
//  Linear2rgbLUT.swift
//  SwiFractal
//
//  Created by Dirk Braner on 03.10.26.
//

import Foundation


///
/// Linear to RGB lookup table
///
final class LinearToRGB : @unchecked Sendable {

    private let table: UnsafeMutablePointer<Float>
    
    static let divOneBy2dot4: Float = 1.0 / 2.4
    static let lastIndex: Float = Float(RGBAColor.maxColors - 1)
    static let lastIndexMinusOne: Int = RGBAColor.maxColors - 2

    /// Initialize lookup table for *RGBAColor.maxColor* colors
    init() {
        let n = RGBAColor.maxColors
        table = .allocate(capacity: n)
        for i in 0..<n {
            let x = Float(i) / Self.lastIndex
            table[i] = x <= 0.0031308
                ? x * 12.92
                : 1.055 * powf(x, Self.divOneBy2dot4) - 0.055
        }
    }
    
    // Free memory
    deinit { table.deallocate() }
    
    /// Convert linear color channel to RGB color channel
    /// - Parameter x: Linear color channel value in range 0...1
    /// - Returns: RGB color channel value in range 0...1
    @inline(__always)
    func callAsFunction(_ x: Float) -> Float {
        let t = x.clamped * Self.lastIndex           // Position in table
        let i = min(Int(t), Self.lastIndexMinusOne)  // Index of left table entry
        let f = t - Float(i)                         // Fractional part between i and i+1
        
        // Linear interpolation
        return Float.lerp(a: table[i], b: table[i + 1], t: f)
    }
    
    /// Convert linear color to RGBA color
    /// - Parameter x: Linear color
    /// - Returns: RGBA color
    @inline(__always)
    func callAsFunction(_ x: SIMD3<Float>) -> RGBAColor {
        return RGBAColor(self(x.x), self(x.y), self(x.z))
    }
    
}

