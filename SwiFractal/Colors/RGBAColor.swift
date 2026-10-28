//
//  Color.swift
//
//  Implementation of type RGBAColor
//
//  Created by Dirk Braner on 19.11.24.
//

import Foundation
import SwiftUI
import simd


/// Type for SIMD3``<Float>``
typealias SIMD3f = SIMD3<Float>

/// Type for RGB color value with components in range 0...1
typealias RGB = SIMD3<Float>

/// Type for RGBA color value with components in range 0...1
typealias RGBA = SIMD4<Float>

/// Type for HSB color value
typealias HSB = (hue: Float, saturation: Float, brightness: Float)

/// Type for HSL color value
typealias HSL = (hue: Float, saturation: Float, lightness: Float)

/// Type for OKLCH / LCH color value
typealias LCH = (lightness: Float, chroma: Float, hue: Float)



///
/// Fractal color type.
/// A RGBAColor has 4 channels: red green, blue, alpha.
/// Each channel is in range 0..1. Channels are stored internally as SIMD4``<Float>``
///
struct RGBAColor: FractalParameters {
    
    /// Maximum number of colors
    static let maxColors = 4096
    
    /// Lookup table for conversion between linear and RGB
    static let linearToRGB = LinearToRGB()
    
    // Predefined colors
    static let black  = RGBAColor(0.0, 0.0, 0.0, 1.0)
    static let white  = RGBAColor(1.0, 1.0, 1.0, 1.0)
    static let red    = RGBAColor(1.0, 0.0, 0.0, 1.0)
    static let green  = RGBAColor(0.0, 1.0, 0.0, 1.0)
    static let blue   = RGBAColor(0.0, 0.0, 1.0, 1.0)
    static let yellow = RGBAColor(1.0, 1.0, 0.0, 1.0)
    
    // Custom encoding to prevent raw SIMD4 encoding of "colorValue"
    enum CodingKeys: String, CodingKey {
        case red, green, blue, alpha
    }
    
    // Color channels: Float values in range 0..1
    var colorValue: SIMD4<Float>
    
    /// Access red component of RGBAColor value
    var red: Float {
        get { colorValue.x }
        set { colorValue.x = newValue }
    }

    /// Access green component of RGBAColor value
    var green: Float {
        get { colorValue.y }
        set { colorValue.y = newValue }
    }
    
    /// Access blue component of RGBAColor value
    var blue: Float {
        get { colorValue.z }
        set { colorValue.z = newValue }
    }
    
    /// Access alpha component of RGBAColor value
    var alpha: Float {
        get { colorValue.w }
        set { colorValue.w = newValue }
    }
    
    /// Access RGB components of RGBAColor value
    var rgb: SIMD3<Float> {
        get { colorValue.xyz }
        set { colorValue.xyz = newValue }
    }
    
    /// Return red channel as UInt8 value in range 0..255
    var redi:   UInt8 { return UInt8(red * 255.0) }

    /// Return green channel as UInt8 value in range 0..255
    var greeni: UInt8 { return UInt8(green * 255.0) }

    /// Return blue channel as UInt8 value in range 0..255
    var bluei:  UInt8 { return UInt8(blue * 255.0) }

    /// Return alpha channel as UInt8 value in range 0..255
    var alphai: UInt8 { return UInt8(alpha * 255.0) }
    
    /// Return color channels as 32 bit integer in format 0xRRGGBBAA
    var rgbi32: UInt32 {
        return UInt32((UInt32(redi) << 24) | (UInt32(greeni) << 16) | (UInt32(bluei) << 8) | UInt32(alphai))
    }
    
    /// Return color channels as 32 bit integer in format 0xAARRGGBB
    var argb8888: UInt32 {
        return UInt32((UInt32(bluei) << 24) | (UInt32(greeni) << 16) | (UInt32(redi) << 8) | UInt32(alphai))
    }

    /// Return color channels as CGColor object
    var cgColor: CGColor {
        return CGColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: CGFloat(alpha))
    }
    
    /// Return color chanels as Swift UI Color object
    var color: Color {
        return Color(red: Double(red), green: Double(green), blue: Double(blue), opacity: Double(alpha))
    }
    
    /// Return color as linear color
    var asLinear: SIMD3<Float> {
        let c = colorValue.xyz
        let low  = c / 12.92
        let high = pow((c + 0.055) / 1.055, SIMD3<Float>(repeating: 2.4))
        return low.replacing(with: high, where: c .> 0.04045)
    }
    
    /// Return all channels as Float vector
    var vector: Vector<Float> {
        return Vector<Float>([red, green, blue, alpha])
    }

    /// Return color channels as vector / Double array
    var vector3: [Float] {
        return [red, green, blue]
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
    
    /// Custom encoder
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(red, forKey: .red)
        try container.encode(green, forKey: .green)
        try container.encode(blue, forKey: .blue)
        try container.encode(alpha, forKey: .alpha)
    }
    
    //
    //  Initialization functions
    //
    
    /// Decoding initializer
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // decodeIfPresent gibt nil zurück, falls der Key im JSON fehlt
        let red = try container.decodeIfPresent(Float.self, forKey: .red) ?? 0.0
        let green = try container.decodeIfPresent(Float.self, forKey: .green) ?? 0.0
        let blue = try container.decodeIfPresent(Float.self, forKey: .blue) ?? 0.0
        let alpha = try container.decodeIfPresent(Float.self, forKey: .alpha) ?? 1.0
        
        self.colorValue = SIMD4<Float>(red, green, blue, alpha)
    }
    
    /// Default initializer (black)
    init() {
        self.colorValue = SIMD4<Float>(0.0, 0.0, 0.0, 1.0)
    }
    
    /// Init color channels with Float values in range 0..1
    init (_ red: Float, _ green: Float, _ blue: Float, _ alpha: Float = 1.0) {
        self.colorValue = SIMD4<Float>(red, green, blue, alpha).clamped
    }
    
    /// Init color channels with Double values in range 0..1
    init (_ red: Double, _ green: Double, _ blue: Double, _ alpha: Double = 1.0) {
        self.init(Float(red), Float(green), Float(blue), Float(alpha))
    }
    
    /// Init color with channels in range 0..255
    init (_ red: UInt8, _ green: UInt8, _ blue: UInt8, _ alpha: UInt8 = 255) {
        self.init(Float(red)/255.0, Float(green)/255.0, Float(blue)/255.0, Float(alpha)/255.0)
    }
    
    /// Init color with RGB / SIMD3 Value
    init(rgb: RGB, _ alpha: Float = 1.0) {
        self.colorValue = RGBA(rgb, alpha).clamped
    }
    
    /// Init color with RGBA / SIMD4 value
    init(rgba: RGBA) {
        self.colorValue = rgba.clamped
    }

    /// Init grey color with Float value
    init(grey: Float, _ alpha: Float = 1.0) {
        self.colorValue = SIMD4<Float>(grey, grey, grey, alpha).clamped
    }
    
    /// Init grey color with Double value
    init(grey: Double, _ alpha: Double = 1.0) {
        self.init(grey: Float(grey), Float(alpha))
    }
    
    /// Init color with vector of channels in range 0..1
    init (vector: [Float]) {
        self.colorValue = SIMD4<Float>(
            vector.count > 0 ? vector[0] : 0.0,
            vector.count > 1 ? vector[1] : 0.0,
            vector.count > 2 ? vector[2] : 0.0,
            vector.count > 3 ? vector[3] : 1.0
        ).clamped
    }
    
    /// Init color with vector of channels in range 0..1
    init (vector: [Double]) {
        self.init(vector: vector.map { Float($0) })
    }
    
    /// Init color with COL3 value (SIMD3 Float)
    init (col3: COL3) {
        self.init(col3.x, col3.y, col3.z, 1.0)
    }
    
    /// Init color with HSB color
    init (hsb: HSB) {
        self.init(col3: ColConv.hsb2rgb(COL3(hsb)))
    }
    
    /// Init with HSL color
    init (hsl: HSL) {
        self.init(col3: ColConv.hsl2rgb(COL3(hsl)))
    }
    
    /// Init with LCH color
    init (lch: LCH) {
        self.init(col3: ColConv.xyz2rgb(ColConv.lab2xyz(ColConv.oklch2lab(COL3(lch.0, lch.1, lch.2)))))
    }

    /// Scale color channels, ignore alpha channel
    /// - Parameter scale: Scaling factor
    /// - Returns: Scaled color. Channels clamped to 0...1
    @inline(__always)
    func scaleRGB(by scale: Float) -> RGBAColor {
        RGBAColor(red * scale, green * scale, blue * scale, alpha)
    }
    
    /// Gamma correction
    /// - Parameter gamma: Gamma value
    /// - Returns: Corrected color
    @inline(__always)
    func gammaCorrection(_ gamma: Float) -> RGBAColor {
        guard gamma != 1.0 else { return self }
        let rcp: Float = 1.0 / gamma
        return RGBAColor(pow(red, rcp), pow(green, rcp), pow(blue, rcp), alpha)
    }
    
    /// Blend color with value using specified blending mode, alpha channel is not touched
    /// - Parameters:
    ///   - value: Blending value (top). Base is current color value (bottom)
    ///   - mode: Blending mode
    ///   - correction: Correction factor. Default = 1.0: no correction
    /// - Returns: Blended color
    @inline(__always)
    func blend(with value: Float, mode: EnumBlendingMode, correction: Float = 1.0) -> RGBAColor {
        guard mode != .none else { return self }
        let col3 = mode.blend(base: self.colorValue.xyz, top: value, correction: correction)
        return RGBAColor(col3: col3)
    }
    
    /// Blend color with a value using specified lightning parameters, alpha channel is not touched.
    /// Gamma correction is applied if gamma is not 1.0.
    /// - Parameters:
    ///   - value: Blending value (top). Base is current color value (bottom)
    ///   - lightning: Lightning parameters
    /// - Returns: Blended color
    func blend(with value: Float, lightning: Lightning) -> RGBAColor {
        let mode = lightning.blendingMode()
        guard mode != .none else { return self }
        
        if mode == .multiply {
            // Blending in linear color space
            let colorLinear = mode.blend(base: self.asLinear, top: value, correction: lightning.exposure)
            let color = RGBAColor.linearToRGB(colorLinear)
            return color.gammaCorrection(lightning.gamma)
        }
        else if mode == .overlay {
            let col3 = mode.blend(base: self.colorValue.xyz, top: value, correction: lightning.gamma)
            return RGBAColor(col3: col3)
        }
        else {
            let col3 = mode.blend(base: self.colorValue.xyz, top: value)
            let color = RGBAColor(col3: col3)
            return color.gammaCorrection(lightning.gamma)
        }
    }
    
    /// Exact linear interpolation between two colors based on a weight factor
    /// - Parameters:
    ///   - from: First color
    ///   - to: Second color
    ///   - factor: Normalized weight factor in range 0...1
    /// - Returns: Interpolated color
    @inline(__always)
    static func lerpExact(from: RGBAColor, to: RGBAColor, factor: Float) -> RGBAColor {
        return RGBAColor(rgba: SIMD4.lerpExact(a: from.colorValue, b: to.colorValue, t: factor.clamped))
    }
    
    /// Linear interpolation between two colors based on a weight factor
    /// - Parameters:
    ///   - from: First color
    ///   - to: Second color
    ///   - factor: Normalized weight factor in range 0...1
    /// - Returns: Interpolated color
    @inline(__always)
    static func lerp(from: RGBAColor, to: RGBAColor, factor: Float) -> RGBAColor {
        return RGBAColor(rgba: SIMD4.lerp(a: from.colorValue, b: to.colorValue, t: factor.clamped))
    }
    
    /// Cosine interpolation
    /// - Parameters:
    ///   - from: First color
    ///   - to: Second color
    ///   - factor: Normalized weight factor in range 0...1
    /// - Returns: Interpolated color
    @inline(__always)
    static func cosineInterpolate(from: RGBAColor, to: RGBAColor, factor: Float) -> RGBAColor {
        RGBAColor(rgba: SIMD4.cosineInterpolate(a: from.colorValue, b: to.colorValue, t: factor))
    }

    /// Compare colors
    static func == (lhs: RGBAColor, rhs: RGBAColor) -> Bool {
        return lhs.colorValue == rhs.colorValue
    }
    
    /// Compare colors
    static func != (lhs: RGBAColor, rhs: RGBAColor) -> Bool {
        return !(lhs == rhs)
    }

    /// Subtract colors
    static func - (lhs: RGBAColor, rhs: RGBAColor) -> RGBAColor {
        return RGBAColor(rgba: lhs.colorValue - rhs.colorValue)
    }
    
    /// Add colors
    static func + (lhs: RGBAColor, rhs: RGBAColor) -> RGBAColor {
        return RGBAColor(rgba: lhs.colorValue + rhs.colorValue)
    }

    ///  Multiply color with float value
    static func * (lhs: RGBAColor, rhs: Float) -> RGBAColor {
        return RGBAColor(rgba: lhs.colorValue * rhs)
    }

    /// Divide color by Float value
    static func / (lhs: RGBAColor, rhs: Float) -> RGBAColor {
        guard rhs != 0 else { return lhs }
        return RGBAColor(rgba: lhs.colorValue / rhs)
    }
    
    /// Linear spacing
    /// - Parameters:
    ///   - start: First color of resulting array
    ///   - end: Last color of resulting array
    ///   - n: Number of colors in resulting array
    /// - Returns: Array with colors
    static func linspace(_ start: RGBAColor, _ end: RGBAColor, _ count: Int) -> [RGBAColor] {
        guard count > 0 else { return [] }
        let step = (end - start) / Float(count - 1)
        var a = Array(0..<count).map { step * Float($0) + start }
        
        // Prevent rounding errors for last array element
        if count > 1 { a[count-1] = end }
        
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
