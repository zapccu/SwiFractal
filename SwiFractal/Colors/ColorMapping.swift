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
enum EnumColorizeMode: Int, CaseIterable {
    case iterations = 0
    case distance   = 1
    case potential  = 2
}
typealias ColorizeMode = Options<EnumColorizeMode>

//
// Outside colorization of a fractal
//
enum EnumColorizeOutside: Int, CaseIterable {
    case simple             // No 3D rendering
    case simple3d           // Simple 3D shading
    case blinnPhong         // Blinn-Phong 3D shading
}
typealias ColorizeOutside = Options<EnumColorizeOutside>

//
// Inside colorization of a fractal
//
enum EnumColorizeInside: Int, CaseIterable {
    case simple
    case orbits             // Colorize orbits inside mandelbrot set, implies full orbit detection
    case distance     // Colorize distance inside mandelbrot set, implies distance calculation
}
typealias ColorizeInside = Options<EnumColorizeInside>

//
// Color Palette Mode
//
// Specifies how iteration results are mapped to a color table
//
enum EnumPaletteMode: Int, CaseIterable {
    case linear    = 0
    case modulo    = 1
    case hue       = 2
    case huedyn    = 3
    case lchdyn    = 4
    case histogram = 5
}
typealias PaletteMode = Options<EnumPaletteMode>

//
// Color Mapping and color related parameters
//
struct ColorMapping {
    var colorTable: String                  // Color table name
    var colorizeMode: ColorizeMode          // Colorize mode: iterations, distance, potential
    var colorizeOutside: ColorizeOutside    // Colorize outside: simple, simple3D, blinnPhong
    var colorizeInside: ColorizeInside
    var paletteMode: PaletteMode            // Palette assignment mode: linear, modulo, hue, huedyn, lchdyn
    
    // Default color if paletteMode is not .linear or .modulo
    var defaultColor: RGBAColor = .black
    
    /// Return color table
    var palette: ColorTable {
        return FractalAppData.colorTables[colorTable, default: ColorTable.grey]
    }
    
    /// Default color defined in color table
    var defColor: RGBAColor {
        return paletteMode.isAny(of: [.linear, .modulo]) ? palette.defColor : defaultColor
    }
    
    /// Number of available colors
    var colorCount: Int {
        return palette.count
    }
    
    /// Initialize color mapping
    init(_ parameterset: ParameterSet = ParameterSet()) {
        colorTable      = parameterset["colorTable", default: "Grey"]
        colorizeMode    = parameterset["colorizeMode", default: ColorizeMode(.iterations)] 
        colorizeOutside = parameterset["colorizeOutside", default: ColorizeOutside(.simple)]
        colorizeInside  = parameterset["colorizeInside", default: ColorizeInside(.simple)]
        paletteMode     = parameterset["paletteMode", default: PaletteMode(.linear)]
        defaultColor    = parameterset["defaultColor", default: RGBAColor.black]
    }
    
    /// Return color table entry or default color
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
    
    /// Overlay function for mandelbrot, equivalent to blendHardLight() with gamma correction
    static func overlay(_ x: Double, _ y: Double, _ gamma: Double) -> Double {
        let out: Double = 2 * y < 1 ? 2 * x * y : 1 - 2 * (1 - x) * (1 - y)
        return out * gamma + x * (1-gamma)
    }
}
