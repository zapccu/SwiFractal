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
enum ColorizeMode: Int, NamedIntEnum {
    case iterations = 0     // iteration count
    case distance   = 1     // distance to Mandelbrot set
    case steps      = 3     // color steps
    case stripes    = 4     // stripes
}

///
/// Colorize outside
///
/// Outside colorization of a fractal
///
enum ColorizeOutside: Int, NamedIntEnum {
    case simple             // No 3D rendering
    case simple3d           // Simple 3D shading
    case blinnPhong         // Blinn-Phong 3D shading
    case filaments          // Draw filaments
}

///
/// Colorize inside
///
/// Inside colorization of a fractal. Raw values must match constants CI_xxx defined in mandelbrot.h
///
enum ColorizeInside: Int, NamedIntEnum {
    case defaultColor = 0   // Inside of Mandelbrot set is set to default color
    case orbits = 1         // Colorize orbits inside Mandelbrot set using full orbit detection
    case brentOrbits = 2    // Brent's period detection
    case brentLambda = 3    // Brent's period detection with lambda calculation for color assignment
    case fastOrbits = 4     // Use fast orbit detection without coloring the interior of Mandelbrot set
    case distance = 5       // Colorize distance inside Mandelbrot set, implies distance calculation
}

///
/// Color Palette Mode
///
/// Specifies how iteration results are mapped to a color table
///
/// Only used when ColorizeMode = .iterations
///
enum PaletteMode: Int, NamedIntEnum {
    case linear           = 0   // linear color mapping
    case interpolated     = 1   // Interpolation
    case hue              = 2
    case huedyn           = 3
    case histogram        = 5   // Histogram color mapping
    case inverseHistogram = 6   // Inverse histogram coloring
    case cycling          = 7
}

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
    
    /// Colorize mode: iterations, distance, steps, stripes
    var colorizeMode: ColorizeMode = .iterations
    
    /// Colorize outside\
    /// `.simple`: No shading\
    /// `.simple3D`: Simple 3D shading (fast)\
    /// `.blinnPhong`: Blinn-Phong 3D shading
    //var colorizeOutside = ColorizeOutside(.simple)      // Colorize outside: simple, simple3D, blinnPhong
    var colorizeOutside: ColorizeOutside = .simple      // Colorize outside: simple, simple3D, blinnPhong
    var colorizeInside: ColorizeInside = .defaultColor  // Colorize inside: defaultColor, orbits, distance
    var paletteMode: PaletteMode = .linear              // Palette assignment mode: linear, modulo, hue, huedyn, lchdyn
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

