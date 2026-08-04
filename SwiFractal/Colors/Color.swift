//
//  Color.swift
//
//  Implementation of type RGBAColor
//
//  Created by Dirk Braner on 19.11.24.
//

import Cocoa
import SwiftUI
import SwiftMPx


// Type for RGBA color value with components in range 0..1
typealias RGBA = SIMD4<Float32>

// Type for RGBAI color values with components in range 0..255
typealias RGBAI = SIMD4<UInt8>

// Type for HSB color value
typealias HSB = (hue: Float, saturation: Float, brightness: Float)

// Type for HSL color value
typealias HSL = (hue: Float, saturation: Float, lightness: Float)

// Type for OKLCH / LCH color value
typealias LCH = (lightness: Float, chroma: Float, hue: Float)

// Extension for RGBA type
extension SIMD4<Float32> {
    
    // Floating point components
    var red: Float   { x }      // red
    var green: Float { y }      // green
    var blue: Float  { z }      // blue
    var alpha: Float { w }      // alpha
    
    // Integer components
    var redi: UInt8   { UInt8(x * 255.0) }
    var greeni: UInt8 { UInt8(y * 255.0) }
    var bluei: UInt8  { UInt8(z * 255.0) }
    var alphai: UInt8 { UInt8(w * 255.0) }
    
    var pixel: [UInt8] { RGBAI(self).pixel }
    
    init(_ x: UInt8, _ y: UInt8, _ z: UInt8, _ w: UInt8) {
        self.init(Float32(x) / 255.0, Float32(y) / 255.0, Float32(z) / 255.0, Float32(w) / 255.0)
    }
    
    init(_ v: SIMD4<UInt8>) {
        self.init(v.x, v.y, v.z, v.w)
    }
}


// Extension for RGBAI type (aka SIMD4<UInt8>)
extension SIMD4<UInt8> {
    
    var red: UInt8   { x }      // red
    var green: UInt8 { y }      // green
    var blue: UInt8  { z }      // blue
    var alpha: UInt8 { w }      // alpha
    
    var pixel: [UInt8] { [x, y, z, w] }
    
    init(_ x: Float, _ y: Float, _ z: Float, _ w: Float) {
        self.init(UInt8(x * 255.0), UInt8(y * 255.0), UInt8(z * 255.0), UInt8(w * 255.0))
    }

    init(_ x: Double, _ y: Double, _ z: Double, _ w: Double) {
        self.init(UInt8(x * 255.0), UInt8(y * 255.0), UInt8(z * 255.0), UInt8(w * 255.0))
    }
    
    init(_ v: SIMD4<Float32>) {
        self.init(v.x, v.y, v.z, v.w)
    }
}


//
// Fractal color type
//
// 4 color channels: red, green, blue, alpha in range 0..1
//
struct RGBAColor: FractalParameters {
    
    // Predefined colors
    static let black  = RGBAColor(0.0, 0.0, 0.0, 1.0)
    static let white  = RGBAColor(1.0, 1.0, 1.0, 1.0)
    static let red    = RGBAColor(1.0, 0.0, 0.0, 1.0)
    static let green  = RGBAColor(0.0, 1.0, 0.0, 1.0)
    static let blue   = RGBAColor(0.0, 0.0, 1.0, 1.0)
    static let yellow = RGBAColor(1.0, 1.0, 0.0, 1.0)
    
    // Color channels: float values in range 0..1
    var red:   Float = 0.0
    var green: Float = 0.0
    var blue:  Float = 0.0
    var alpha: Float = 1.0
    
    /// Return red channel as UInt8 value in range 0..255
    var redi:   UInt8 { return UInt8(red * 255.0) }

    /// Return green channel as UInt8 value in range 0..255
    var greeni: UInt8 { return UInt8(green * 255.0) }

    /// Return blue channel as UInt8 value in range 0..255
    var bluei:  UInt8 { return UInt8(blue * 255.0) }

    /// Return alpha channel as UInt8 value in range 0..255
    var alphai: UInt8 { return UInt8(alpha * 255.0) }

    /// Return color channels as tuple of Float values in range 0..1
    var rgba: RGBA {
        return RGBA(red, green, blue, alpha)
    }
    
    /// Return color channels as 32 bit integer in format 0xRRGGBBAA
    var rgbi32: UInt32 {
        return UInt32((UInt32(redi) << 24) | (UInt32(greeni) << 16) | (UInt32(bluei) << 8) | UInt32(alphai))
    }
    
    /// Return color channels as 32 bit integer in format 0xAARRGGBB
    var argb8888: UInt32 {
        return UInt32((UInt32(bluei) << 24) | (UInt32(greeni) << 16) | (UInt32(redi) << 8) | UInt32(alphai))
    }
    
    /// Return color channels as tuple of UInt8 values in range 0..255
    var rgbai: RGBAI {
        return RGBAI(red, green, blue, alpha)
    }

    /// Return color channels as CGColor object
    var cgColor: CGColor {
        return CGColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: CGFloat(alpha))
    }
    
    /// Return color chanels as Swift UI Color object
    var color: Color {
        return Color(red: Double(red), green: Double(green), blue: Double(blue), opacity: Double(alpha))
    }
    
    /// Return all channels as vector / Double array
    var vector: Vector<Double> {
        return Vector<Double>([Double(red), Double(green), Double(blue), Double(alpha)])
    }

    /// Return color channels as vector / Double array
    var vector3: [Double] {
        return [Double(red), Double(green), Double(blue)]
    }

    /// Return color channels as pixel / UInt8 array
    var pixel: [UInt8] {
        return [redi, greeni, bluei, alphai]
    }
    
    /// Return color channels as COL3
    var col3: COL3 {
        return COL3(red, green, blue)
    }
    
    /// Return a GraphicsContext shading color
    var shadingColor: GraphicsContext.Shading {
        return GraphicsContext.Shading.color(color)
    }
    
    
    // --------------------------------
    //  Initialization functions
    // --------------------------------
    
    /// Init color channels with Float values in range 0..1
    init (_ red: Float = 0.0, _ green: Float = 0.0, _ blue: Float = 0.0, _ alpha: Float = 1.0) {
        self.red   = max(min(red, 1.0), 0.0)
        self.green = max(min(green, 1.0), 0.0)
        self.blue  = max(min(blue, 1.0), 0.0)
        self.alpha = max(min(alpha, 1.0), 0.0)
    }
    
    /// Init color channels with Double values in range 0..1
    init (_ red: Double = 0.0, _ green: Double = 0.0, _ blue: Double = 0.0, _ alpha: Double = 1.0) {
        self.init(Float(red), Float(green), Float(blue), Float(alpha))
    }

    /// Init grey color with Float value
    init(grey: Float, _ alpha: Float = 1.0) {
        self.red = grey
        self.green = grey
        self.blue = grey
        self.alpha = alpha
    }
    
    /// Init grey color with Double value
    init(grey: Double, _ alpha: Double = 1.0) {
        self.init(grey: Float(grey), Float(alpha))
    }
    
    /// Init color with vector of channels in range 0..1
    init (_ vector: [Float]) {
        self.init(
            vector.count > 0 ? vector[0] : 0.0,
            vector.count > 1 ? vector[1] : 0.0,
            vector.count > 2 ? vector[2] : 0.0,
            vector.count > 3 ? vector[3] : 1.0
        )
    }
    
    /// Init color with vector of channels in range 0..1
    init (_ vector: [Double]) {
        self.init(vector.map { Float($0) })
    }

    /// Init color with channels in range 0..255
    init (_ red: UInt8, _ green: UInt8, _ blue: UInt8, _ alpha: UInt8 = 255) {
        self.init(Float(red)/255.0, Float(green)/255.0, Float(blue)/255.0, Float(alpha)/255.0)
    }
    
    /// Init color with RGBA value
    init (_ rgba: RGBA) {
        self.init(rgba.x, rgba.y, rgba.z, rgba.w)
    }
    
    /// Init color with RGBAI value
    init (_ rgbai: RGBAI) {
        self.init(rgbai.red, rgbai.green, rgbai.blue, rgbai.alpha)
    }
    
    /// Init color with COL3 value
    init (_ col3: COL3) {
        self.init(col3.x, col3.y, col3.z, 1.0)
    }
    
    /// Init color with HSB color
    init (_ hsb: HSB) {
        self.init(ColConv.hsb2rgb(COL3(hsb)))
    }
    
    /// Init with HSL color
    init (_ hsl: HSL) {
        self.init(ColConv.hsl2rgb(COL3(hsl)))
    }
    
    /// Init with LCH color
    init (_ lch: LCH) {
        self.init(ColConv.xyz2rgb(ColConv.lab2xyz(ColConv.oklch2lab(COL3(lch.0, lch.1, lch.2)))))
    }
        
    /// Gamma correction
    /// - Parameter gamma: Gamma value
    /// - Returns: Corrected color
    func gammaCorrection(_ gamma: Double) -> RGBAColor {
        guard gamma != 1.0 else { return self }
        let rcp = Float(1.0/gamma)
        return RGBAColor(pow(rgba.red, rcp), pow(rgba.green, rcp), pow(rgba.blue, rcp), rgba.alpha)
    }
    
    /// Overlay, alpha channel is not touched
    mutating func hardLight(top: Float) {
        red   = BlendingMode.hardLight.blend(base: red, top: top)
        green = BlendingMode.hardLight.blend(base: green, top: top)
        blue  = BlendingMode.hardLight.blend(base: blue, top: top)
    }
    
    /// Linear interpolation between two colors based on a weight factor
    /// - Parameters:
    ///   - other: Other color
    ///   - factor: Weight factor in range 0...1
    mutating func mix(with other: RGBAColor, factor: Float) {
        let clampedFactor = min(max(factor, 0.0), 1.0)
        red   = red   * (1.0 - clampedFactor) + other.red   * clampedFactor
        green = green * (1.0 - clampedFactor) + other.green * clampedFactor
        blue  = blue  * (1.0 - clampedFactor) + other.blue  * clampedFactor
    }
    
    // --------------------------------
    //  Compare colors
    // --------------------------------

    static func == (lhs: RGBAColor, rhs: RGBAColor) -> Bool {
        return lhs.rgba == rhs.rgba
    }
    
    static func != (lhs: RGBAColor, rhs: RGBAColor) -> Bool {
        return !(lhs == rhs)
    }
    
    // --------------------------------
    //  Subtract / add colors
    // --------------------------------

    static func - (lhs: RGBAColor, rhs: RGBAColor) -> RGBAColor {
        return RGBAColor(lhs.red - rhs.red, lhs.green - rhs.green, lhs.blue - rhs.blue, lhs.alpha - rhs.alpha)
    }
    
    static func + (lhs: RGBAColor, rhs: RGBAColor) -> RGBAColor {
        return RGBAColor(lhs.red + rhs.red, lhs.green + rhs.green, lhs.blue + rhs.blue, lhs.alpha + rhs.alpha)
    }

    // --------------------------------------------------------
    //  Multiply / divide colors with/by float or double value
    //  Alpha channel is not modified!
    // --------------------------------------------------------

    static func * (lhs: RGBAColor, rhs: Float) -> RGBAColor {
        return RGBAColor(lhs.red * rhs, lhs.green * rhs, lhs.blue * rhs, lhs.alpha)
    }

    static func / (lhs: RGBAColor, rhs: Float) -> RGBAColor {
        guard rhs != 0 else { return lhs }
        return RGBAColor(lhs.red / rhs, lhs.green / rhs, lhs.blue / rhs, lhs.alpha)
    }
    
    /// Linear spacing
    /// - Parameters:
    ///   - start: First color of resulting array
    ///   - end: Last color of resulting array
    ///   - n: Number of colors in resulting array
    /// - Returns: Array with colors
    static func linspace(_ start: RGBAColor, _ end: RGBAColor, _ n: Int) -> [RGBAColor] {
        guard n > 0 else { return [] }
        let step = (end - start) / Float(n - 1)
        var a = Array(0..<n).map { step * Float($0) + start }
        
        // Prevent rounding errors for last array element
        if n > 1 { a[n-1] = end }
        
        return a
    }
    
}

#if os(macOS)
extension NSColor {
    convenience init(_ color: RGBAColor) {
        self.init(red: CGFloat(color.red), green: CGFloat(color.green), blue: CGFloat(color.blue), alpha: CGFloat(color.alpha))
    }
}
#endif

#if os(iOS)
extension UIColor {
    convenience init(_ color: RGBAColor) {
        self.init(red: CGFloat(color.red), green: CGFloat(color.green), blue: CGFloat(color.blue), alpha: CGFloat(color.alpha))
    }
}
#endif
