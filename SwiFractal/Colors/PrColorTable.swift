//
//  PrColorTable.swift
//  SwiFractal
//
//  Created by Dirk Braner on 17.08.26.
//

import Foundation


///
/// Protocol for color tables
///
protocol ColorTable : Coloring, FractalParameters {
    
    /// Color array
    var colors: [RGBAColor] { get set }
    
    /// Color array as array of RGBA colors
    var rgbaColors: [RGBA] { get set }
        
    /// Size of color table
    var count: Int { get set }
    
    /// Color table has fixed size
    var fixedSize: Bool { get set }
    
    /// Color table is cyclic
    var cyclic: Bool { get }

    /// Return color table entry or default color
    subscript (_: Int, _: Float) -> RGBAColor { get }

    /// Clone color table
    func clone(colorCount: Int) -> Self
    
    /// Resize color table
    mutating func resize(colorCount: Int) -> Int
    
}

extension ColorTable {
    
    /// Convert between RGBAColor array and RGBA color array
    var rgbaColors: [RGBA] {
        get { colors.map { $0.colorValue } }
        set { colors = newValue.map { RGBAColor(rgba: $0) } }
    }
    
    /// Return color table entry at specified Int index.
    @inline(__always) subscript(_ index: Int, _ brightness: Float = 1.0) -> RGBAColor {
        guard index >= 0, index < colors.count else { return defColor }
        return colors[index] * brightness
    }
    
    /// Return color table entry for index in range 0-1 mapped to color table
    @inline(__always) subscript(_ index: Float, _ brightness: Float = 1.0) -> RGBAColor {
        let index = Int(index.clamped * Float(count-1))
        return self[index, brightness]
    }
    
    /// Linear color mapping based on smooth iteration value
    /// - Parameters:
    ///   - smoothIter: Smooth iteration value in range 1...MaxIter. Usually result of *compress()*
    ///   - scale: Frequency of color changing
    ///   - offset: Offset to first value in color table
    ///   - ncycle: Defines how many iterations correlate with 1 cycle. Modulo division by ncycle allows to determine after how many (transformed)
    ///   iteration steps the color repeats, regardless of the absolute iteration depth. 1 = Full color cycle every 1 iteration (default).
    ///   ncycle must be >= 1.
    /// - Returns: Mapped color value
    ///
    /// **Use of scale**
    ///
    /// **Effects on iterations**
    ///
    /// Scale =  0.01 - 1: It takes 1/scale iterations to get from one color to next color in color table.
    ///
    /// Scale = 1 - 50: Within 1 iteration step palette is passed through *scale* times.
    ///
    /// **Effects on coloring**
    ///
    /// Scale = 0.01 - 0.1: Colors are changing very slowly. Glowing effect around Mandelbrot set. Wide color areas, no color ring effects.
    /// Useful for deep zooms with rapidly changing iteration values.
    ///
    /// Scale = 2.0 - 20.0: Ring structures. Detailed structures close to Mandelbrot set are better visible.
    ///
    /// Scale = 20.0 - 50.0: Moire effects. 3D looks.
    ///
    /*
    func getColor(smoothIter: Double, scale: Double, offset: Double, ncycle: Double) -> RGBAColor {
        guard count > 0 else { return defColor }
        guard count > 1 else { return colors[0] }
     
        let sc: Double = scale.clamped(to: 0.01...50.0)
        let nc = max(ncycle, 1.0)

        var virtualIndex: Double
        var i1: Int                 // Index 1 for interpolation
        var i2: Int                 // Index 2 for interpolation
        
        let interval: Double = cyclic ? 1.0 : 2.0
        
        let x = smoothIter * sc + offset
        var rawIndex = (fmod(x, nc) / nc) * interval
        if rawIndex < 0 { rawIndex += interval }
        
        if cyclic {
            // First and last color of palette are identical
            // Modulo divisions are necessary to prevent out of bound errors due to roundings
            virtualIndex = rawIndex * Double(count)
            i1 = Int(floor(virtualIndex)) % count
            i2 = (i1 + 1) % count
        }
        else {
            // First and last color of palette are different. Reverse index
            rawIndex = rawIndex <= 1.0 ? rawIndex : (2.0 - rawIndex)
            virtualIndex = rawIndex * Double(count - 1)
            i1 = Int(floor(virtualIndex))
            i2 = min(i1 + 1, count - 1)
        }

        let t = Float(virtualIndex - floor(virtualIndex))

        return RGBAColor.cosineInterpolate(from: colors[i1], to: colors[i2], factor: t)
    }
     */
    
    /// Get color base on transformed iteration counter considering cyclic and non cyclic color tables
    /// - Parameter t: Transformed smooth iteration counter in range 0...1
    /// - Returns: Color
    func getColor(t: Double) -> RGBAColor {
        var virtualIndex: Double
        var i1: Int                 // Index 1 for interpolation
        var i2: Int                 // Index 2 for interpolation

        let interval: Double = cyclic ? 1.0 : 2.0

        var rawIndex = t * interval
        if rawIndex < 0 { rawIndex += interval }
        
        if cyclic {
            // First and last color of palette are identical
            // Modulo divisions are necessary to prevent out of bound errors due to roundings
            virtualIndex = rawIndex * Double(count)
            i1 = Int(floor(virtualIndex)) % count
            i2 = (i1 + 1) % count
        }
        else {
            // First and last color of palette are different. Reverse index
            rawIndex = rawIndex <= 1.0 ? rawIndex : (2.0 - rawIndex)
            virtualIndex = rawIndex * Double(count - 1)
            i1 = Int(floor(virtualIndex))
            i2 = min(i1 + 1, count - 1)
        }

        let t = Float(virtualIndex - floor(virtualIndex))

        return RGBAColor.cosineInterpolate(from: colors[i1], to: colors[i2], factor: t)
    }
    
    /// Get color based on integer iteration counter considering cyclic and non cyclic color tables
    /// - Parameters:
    ///   - iter: Iteration counter. Must be greater than 0.
    ///   - maxIter: Max iterations. Must be greater than or equal to iter.
    /// - Returns: Color
    func getColor(iter: Int, maxIter: Int) -> RGBAColor {
        guard iter > 0 && maxIter >= iter else { return defColor }
        let t = Double(iter) / Double(maxIter)
        return getColor(t: t)
    }
    
    /// Get color based on floating point iteration counter
    /// - Parameter vindex: Virtual index in range 0...1
    /// - Returns: Color
    @inline(__always)
    func getColor(vindex: Double) -> RGBAColor {
        let index = Int(round(vindex.clamped * Double(count - 1)))
        return colors[index]
    }
}
