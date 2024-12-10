//
//  Color.swift
//
//  Created by Dirk Braner on 19.11.24.
//

import Cocoa

typealias RGBA = (red: Float, green: Float, blue: Float, alpha: Float)
typealias RGBAI = (red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8)
typealias HSB = (hue: Float, saturation: Float, brightness: Float)
typealias HSL = (hue: Float, saturation: Float, lightness: Float)

struct RGBAColor {
    
    // Predefined colors
    static let black  = RGBAColor(0.0, 0.0, 0.0, 1.0)
    static let white  = RGBAColor(1.0, 1.0, 1.0, 1.0)
    static let red    = RGBAColor(1.0, 0.0, 0.0, 1.0)
    static let green  = RGBAColor(0.0, 1.0, 0.0, 1.0)
    static let blue   = RGBAColor(0.0, 0.0, 1.0, 1.0)
    static let yellow = RGBAColor(1.0, 1.0, 0.0, 1.0)
    
    // Channels: Float values in range 0..1
    var rgba = RGBA(0, 0, 0, 1)
    
    // Access channels
    var red : Float {
        get { return rgba.red }
        set { rgba.red = min(max(newValue,0),1) }
    }
    var green : Float {
        get { return rgba.green }
        set { rgba.green = min(max(newValue,0),1) }
    }
    var blue : Float {
        get { return rgba.blue }
        set { rgba.blue = min(max(newValue,0),1) }
    }
    var alpha : Float {
        get { return rgba.alpha }
        set { rgba.alpha = min(max(newValue,0),1) }
    }
    
    var redi: UInt8 { return UInt8(rgba.red*255.0) }
    var greeni: UInt8 { return UInt8(rgba.green*255.0) }
    var bluei: UInt8 { return UInt8(rgba.blue*255.0) }
    var alphai: UInt8 { return UInt8(rgba.alpha*255.0) }

    // Channels: Int values in range 0..255
    var rgbai: RGBAI { return RGBAI(UInt8(rgba.red*255.0), UInt8(rgba.green*255.0), UInt8(rgba.blue*255.0), UInt8(rgba.alpha*255.0)) }
    
    // --------------------------------
    //  Initialization functions
    // --------------------------------
    
    init (_ red: Float = 0.0, _ green: Float = 0.0, _ blue: Float = 0.0, _ alpha: Float = 1.0) {
        rgba = RGBA(max(min(red, 1.0), 0.0), max(min(green, 1.0), 0.0), max(min(blue, 1.0), 0.0), max(min(alpha, 1.0), 0.0))
    }
    
    init (_ red: Double = 0.0, _ green: Double = 0.0, _ blue: Double = 0.0, _ alpha: Double = 1.0) {
        self.init(Float(red), Float(green), Float(blue), Float(alpha))
    }
    
    init (_ red: Int, _ green: Int, _ blue: Int, _ alpha: Int = 255) {
        self.init(Float(red)/255.0, Float(green)/255.0, Float(blue)/255.0, Float(alpha)/255.0)
    }
    
    init (_ rgba: RGBA = RGBA(0, 0, 0, 1)) {
        self.init(rgba.red, rgba.green, rgba.blue, rgba.alpha)
    }
    
    // Init with HSB color
    init (_ hsb: HSB) {
        if hsb.saturation == 0.0 {
            // Grey
            self.init(hsb.brightness, hsb.brightness, hsb.brightness, 1.0)
        }
        else {
            var i = Int(hsb.hue * 6.0)
            let f = (hsb.hue * 6.0) - Float(i)
            let p = hsb.brightness * (1.0 - hsb.saturation)
            let q = hsb.brightness * (1.0 - hsb.saturation * f)
            let t = hsb.brightness * (1.0 - hsb.saturation * (1.0 - f))
            let v = hsb.brightness
            i = i % 6
            
            switch i {
            case 0: self.init(v, t, p, 1.0)
            case 1: self.init(q, v, p, 1.0)
            case 2: self.init(p, v, t, 1.0)
            case 3: self.init(p, q, v, 1.0)
            case 4: self.init(t, p, v, 1.0)
            case 5: self.init(v, p, q, 1.0)
            default: self.init(0, 0, 0, 1.0)
            }
        }
    }
    
    // Init with HSL color
    init (_ hsl: HSL) {
        func hueToRgb(_ p: Float, _ q: Float, _ t: Float) -> Float {
            var x = t

            if x < 0 { x += 1 }
            else if x > 1 { x -= 1 }
            
            if x < 1/6 { return p + (q - p) * 6 * x }
            if x < 1/2 { return q }
            if x < 2/3 { return p + (q - p) * (2/3 - x) * 6 }
            
            return p
        }

        if hsl.saturation == 0.0 {
            // Grey
            self.init(hsl.lightness, hsl.lightness, hsl.lightness, 1.0)
        }
        else {
            let q = hsl.lightness < 0.5 ? hsl.lightness * (1 + hsl.saturation) : hsl.lightness + hsl.saturation - hsl.lightness * hsl.saturation
            let p = 2 * hsl.lightness - q
            
            let r = hueToRgb(p, q, hsl.hue + 1/3)
            let g = hueToRgb(p, q, hsl.hue)
            let b = hueToRgb(p, q, hsl.hue - 1/3)
            
            self.init(r, g, b, 1.0)
        }
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
        rgba.red = Float(ColorMapping.overlay(Double(rgba.red), y, gamma))
        rgba.green = Float(ColorMapping.overlay(Double(rgba.green), y, gamma))
        rgba.blue = Float(ColorMapping.overlay(Double(rgba.blue), y, gamma))
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
        return RGBAColor(lhs.rgba.red - rhs.rgba.red, lhs.rgba.green - rhs.rgba.green, lhs.rgba.blue - rhs.rgba.blue, lhs.rgba.alpha - rhs.rgba.alpha)
    }
    
    static func + (lhs: RGBAColor, rhs: RGBAColor) -> RGBAColor {
        return RGBAColor(lhs.rgba.red + rhs.rgba.red, lhs.rgba.green + rhs.rgba.green, lhs.rgba.blue + rhs.rgba.blue, lhs.rgba.alpha + rhs.rgba.alpha)
    }

    // --------------------------------------------------------
    //  Multiply / divide colors with/by float or double value
    // --------------------------------------------------------

    static func * (lhs: RGBAColor, rhs: Float) -> RGBAColor {
        return RGBAColor(lhs.rgba.red * rhs, lhs.rgba.green * rhs, lhs.rgba.blue * rhs, lhs.rgba.alpha * rhs)
    }

    static func / (lhs: RGBAColor, rhs: Float) -> RGBAColor {
        guard rhs != 0 else { return lhs }
        return RGBAColor(lhs.rgba.red / rhs, lhs.rgba.green / rhs, lhs.rgba.blue / rhs, lhs.rgba.alpha / rhs)
    }
}

#if os(macOS)
extension NSColor {
    convenience init(_ color: RGBAColor) {
        self.init(red: CGFloat(color.rgba.red), green: CGFloat(color.rgba.green), blue: CGFloat(color.rgba.blue), alpha: CGFloat(color.rgba.alpha))
    }
}
#endif

#if os(iOS)
extension UIColor {
    convenience init(_ color: RGBAColor) {
        self.init(red: CGFloat(color.rgba.red), green: CGFloat(color.rgba.green), blue: CGFloat(color.rgba.blue), alpha: CGFloat(color.rgba.alpha))
    }
}
#endif
