//
//  ColorMapping.swift
//  SwiFractal
//
//  Created by Dirk Braner on 24.11.24.
//

import Foundation
import Numerics


///
/// Colorize Mode
///
/// Specifies the kind of value used to calculate the color
///
enum EnumColorizeMode: Int, CaseIterable {
    case iterations = 0     // iteration count
    case distance   = 1     // distance to Mandelbrot set
    case potential  = 2     // potential of fractal point
    case steps      = 3     // color steps
    case stripes    = 4     // stripes
}
typealias ColorizeMode = Options<EnumColorizeMode>

///
/// Colorize outside
///
/// Outside colorization of a fractal
///
enum EnumColorizeOutside: Int, CaseIterable {
    case simple             // No 3D rendering
    case simple3d           // Simple 3D shading
    case blinnPhong         // Blinn-Phong 3D shading
    case filaments          // Draw filaments
}
typealias ColorizeOutside = Options<EnumColorizeOutside>

///
/// Colorize inside
///
/// Inside colorization of a fractal
///
enum EnumColorizeInside: Int, CaseIterable {
    case defaultColor       // Inside of Mandelbrot set is set to default color
    case fastOrbits         // Colorize orbits inside Mandelbrot using fast orbit detection
    case orbits             // Colorize orbits inside Mandelbrot using full orbit detection
    case distance           // Colorize distance inside Mandelbrot set, implies distance calculation
}
typealias ColorizeInside = Options<EnumColorizeInside>

///
/// Color Palette Mode
///
/// Specifies how iteration results are mapped to a color table
///
/// Only used when ColorizeMode = .iterations
///
enum EnumPaletteMode: Int, CaseIterable {
    case linear           = 0   // linear color mapping
    case interpolated     = 1   // Interpolation
    case hue              = 2
    case huedyn           = 3
    case histogram        = 5   // Histogram color mapping
    case inverseHistogram = 6   // Inverse histogram coloring
    case cycling          = 7
}
typealias PaletteMode = Options<EnumPaletteMode>

///
/// Color parameters
///
struct FractalColorParameters: FractalParameters {
    
    /// Coloring name
    var coloringName: String = "Grey-1024"
    
    /// Coloring. Default = Greyscale color table with 1024 colors
    var coloring: EnumColoring = .smooth(smoothColorTable: ColorTableSmooth(
        "Grey-1024", colorPoints: [RGBAColor(80.0/255.0, 80.0/255.0, 80.0/255.0), .white], colorCount: 1024, defColor: .black)
    )
    
    /// Colorize mode: iterations, distance, potential, steps, stripes
    var colorizeMode = ColorizeMode(.iterations)
    
    /// Colorize outside\
    /// `.simple`: No shading\
    /// `.simple3D`: Simple 3D shading (fast)\
    /// `.blinnPhong`: Blinn-Phong 3D shading
    var colorizeOutside = ColorizeOutside(.simple)      // Colorize outside: simple, simple3D, blinnPhong
    var colorizeInside = ColorizeInside(.defaultColor)  // Colorize inside: defaultColor, fastOrbits, orbits, distance
    var paletteMode = PaletteMode(.linear)              // Palette assignment mode: linear, modulo, hue, huedyn, lchdyn
    var stripes: Int = 0                                // Stripe density, frequency for stripe average coloring
                                                        // Range 0-32, 0 = No stripes, default = 0
    var stripeSig: Double = 0.9                         // Memory parameter for stripe average coloring
                                                        // Range 0-1, 0 = No stripes, default = 0.9
    var steps: Int = 0                                  // Step density, frequency for step coloring
                                                        // Range 0-100, 0 = No steps, default = 0
    var ncycle: Double = 1.0                            // Color cycling, must be > 0
    var scale: Double = 1.0                             // Color changing frequency
    
    var offset: Double = 0.0                            // Offset to first color
    var compression: Int = 1                            // Color palette compression. nth root of iteration count, must be > 0

}

