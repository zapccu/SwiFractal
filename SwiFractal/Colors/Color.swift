//
//  Color.swift
//
//  Implementation of type RGBAColor
//
//  Created by Dirk Braner on 19.11.24.
//

import Cocoa
import SwiftUI

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
struct RGBAColor: Castable {
    static func isCastable<T>(from: T) -> Bool {
        return from is RGBAColor
    }
    
    static func cast<T>(from: T) -> any Castable where T : Castable {
        if let v = from as? RGBAColor {
            return v
        } else {
            return defaultValue
        }
    }
    
    static var defaultValue: RGBAColor = .black
    
    
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
    var alpha: Float = 0.0
    
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
    
    /// Return color channels as 32 bit integer
    var rgbi32: Int32 {
        return Int32((UInt32(redi) << 24) | (UInt32(greeni) << 16) | (UInt32(bluei) << 8) | UInt32(alphai))
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
    var vector: [Double] {
        return [Double(red), Double(green), Double(blue), Double(alpha)]
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
    
    /// Init color with channels in range 0..1
    init (_ red: Float = 0.0, _ green: Float = 0.0, _ blue: Float = 0.0, _ alpha: Float = 1.0) {
        self.red = max(min(red, 1.0), 0.0)
        self.green = max(min(green, 1.0), 0.0)
        self.blue = max(min(blue, 1.0), 0.0)
        self.alpha = max(min(alpha, 1.0), 0.0)
    }
    
    /// Init color with channels in range 0..1
    init (_ red: Double = 0.0, _ green: Double = 0.0, _ blue: Double = 0.0, _ alpha: Double = 1.0) {
        self.init(Float(red), Float(green), Float(blue), Float(alpha))
    }

    /// Init color with channels in range 0..1
    init (_ vector: [Double]) {
        self.init(
            vector.count > 0 ? Float(vector[0]) : 0.0,
            vector.count > 1 ? Float(vector[1]) : 0.0,
            vector.count > 2 ? Float(vector[2]) : 0.0,
            vector.count > 3 ? Float(vector[3]) : 1.0
        )
    }

    /// Init color with channels in range 0..255
    init (_ red: UInt8, _ green: UInt8, _ blue: UInt8, _ alpha: UInt8 = 255) {
        self.init(Float(red)/255.0, Float(green)/255.0, Float(blue)/255.0, Float(alpha)/255.0)
    }
    
    /// Init color with RGBA value
    init (_ rgba: RGBA = RGBA(0.0, 0.0, 0.0, 1.0)) {
        self.init(rgba.x, rgba.y, rgba.z, rgba.w)
    }
    
    /// Init color with RGBAI value
    init (_ rgbai: RGBAI = RGBAI(UInt8(0), UInt8(0), UInt8(0), UInt8(255))) {
        self.init(rgbai.red, rgbai.green, rgbai.blue, rgbai.alpha)
    }
    
    /// Init color with COL3 value
    init (_ col3: COL3 = COL3(0.0, 0.0, 0.0)) {
        self.init(col3.x, col3.y, col3.z, 1.0)
    }
    
    /// Init color with HSB color
    init (_ hsb: HSB) {
        self.init(hsb2rgb(COL3(hsb)))
    }
    
    /// Init with HSL color
    init (_ hsl: HSL) {
        self.init(hsl2rgb(COL3(hsl)))
    }
    
    /// Init with LCH color
    init (_ lch: LCH) {
        self.init(xyz2rgb(lab2xyz(oklch2lab(COL3(lch.0, lch.1, lch.2)))))
    }
        
    /// Gamma correction
    func gammaCorrection(_ gamma: Double) -> RGBAColor {
        if gamma != 1.0 {
            let rcp = Float(1.0/gamma)
            return RGBAColor(pow(rgba.red, rcp), pow(rgba.green, rcp), pow(rgba.blue, rcp), rgba.alpha)
        }
        
        return RGBAColor(rgba)
    }
    
    /// Overlay, alpha channel is not touched
    mutating func overlay(_ y: Double, _ gamma: Double) {
        red = Float(ColorMapping.overlay(Double(red), y, gamma))
        green = Float(ColorMapping.overlay(Double(green), y, gamma))
        blue = Float(ColorMapping.overlay(Double(blue), y, gamma))
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
    // --------------------------------------------------------

    static func * (lhs: RGBAColor, rhs: Float) -> RGBAColor {
        return RGBAColor(lhs.red * rhs, lhs.green * rhs, lhs.blue * rhs, lhs.alpha * rhs)
    }

    static func / (lhs: RGBAColor, rhs: Float) -> RGBAColor {
        guard rhs != 0 else { return lhs }
        return RGBAColor(lhs.red / rhs, lhs.green / rhs, lhs.blue / rhs, lhs.alpha / rhs)
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
