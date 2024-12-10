//
//  ColorMapping.swift
//  SwiFractal
//
//  Created by Dirk Braner on 24.11.24.
//

import Foundation
import ComplexModule

//
// Colorize Mode
//
// Specifies the iteration value used to calculate the color
//
// iterations - use iteration count
// distance   - use distance to Mandelbrot set
// potential  - use potential of fractal point
//
enum ColorizeMode: Int {
    case iterations = 0
    case distance   = 1
    case potential  = 2
}

//
// Colorize Options
//
// Combination of flags defining how a fractal is colorized
//
// orbits         - colorize orbits inside Mandelbrot set
// insideDistance - calculate distance inside Mandelbrot set
// simple3D       - simple 3D shading
// blinnPhong     - Blinn-Phong 3D shading
//
// If both .simple3D and .blinnPhong are set, .simple3D is used
//
enum ColorizeFlags: UInt {
    case simple = 0
    case orbits = 1
    case insideDistance = 2
    case simple3d = 4
    case blinnPhong = 8
}

typealias ColorizeOptions = Bitfield<ColorizeFlags>

extension Bitfield where T: RawRepresentable, T == ColorizeFlags {
    static let simple           = Bitfield(.simple)
    static let orbits           = Bitfield(.orbits)
    static let insideDistance   = Bitfield(.insideDistance)
    static let simple3d         = Bitfield(.simple3d)
    static let blinnPhong       = Bitfield(.blinnPhong)
    
    static let shading: Bitfield = .simple3d | .blinnPhong
}

//
// Color Palette Mode
//
// Specifies how iteration results are mapped to a color table
//
enum PaletteMode: Int {
    case linear = 0
    case modulo = 1
    case hue    = 2
    case huedyn = 3
    case lchdyn = 4
}

struct ColorMapping {
    var palette: ColorTable
    var colorizeMode: ColorizeMode
    var colorizeOptions: ColorizeOptions
    var paletteMode: PaletteMode
    
    // Default color if paletteMode is not .linear or .modulo
    var defaultColor: RGBAColor = .black
    
    /// Default color defined in color table
    var defColor: RGBAColor {
        return paletteMode == .linear || paletteMode == .modulo ? palette.defColor : defaultColor
    }
    
    /// Number of available colors
    var colorCount: Int {
        return palette.count
    }
    
    /// Initialize color mapping
    init(_ parameterset: ParameterSet = ParameterSet()) {
        palette         = parameterset["colorTable", .greyScale]
        colorizeMode    = parameterset["colorizeMode", .iterations]
        colorizeOptions = parameterset["colorizeOptions", .simple]
        paletteMode     = parameterset["paletteMode", .linear]
        defaultColor    = parameterset["defaultColor", .black]
    }
    
    subscript(_ index: Int) -> RGBAColor {
        guard index >= 0, index < colorCount else { return defColor }
        return palette[index]
    }
    
    /// Overlay blending: a = base layer, b = top layer
    static func blendOverlay(_ a: Double, _ b: Double) -> Double {
        return a < 0.5 ? 2 * a * b : 1 - 2 * (1 - a) * (1 - b)
    }
    
    /// Hard light blending: a = base layer, b = top layer
    static func blendHardLight(_ a: Double, _ b: Double) -> Double {
        return b < 0.5 ? 2 * a * b : 1 - 2 * (1 - a) * (1 - b)
    }
    
    /// Soft light blending (W3C draft)
    static func blendSoftLight(_ a: Double, _ b: Double) -> Double {
        let g = a <= 0.25 ? ((16 * a - 12) * a + 4) * a : sqrt(a)
        return b <= 0.5 ? a - (1 - 2 * b) * a * (1 - a) : a + (2 * b - 1) * (g - a)
    }
    
    /// Overlay function from GPU Mandelbrot, equivalent to blendHardLight()
    static func overlay(_ x: Double, _ y: Double, _ gamma: Double) -> Double {
        let out: Double = 2 * y < 1 ? 2 * x * y : 1 - 2 * (1 - x) * (1 - y)
        
        return out * gamma + x * (1-gamma)
    }
}
