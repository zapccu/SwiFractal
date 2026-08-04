//
//  ColorMapping.swift
//  SwiFractal
//
//  Created by Dirk Braner on 24.11.24.
//

import Foundation
import Numerics

//
// Colorize Mode
//
// Specifies the kind of value used to calculate the color
//
enum EnumColorizeMode: Int, CaseIterable {
    case iterations = 0     // iteration count
    case distance   = 1     // distance to Mandelbrot set
    case potential  = 2     // potential of fractal point
    case steps      = 3     // color steps
    case stripes    = 4     // stripes
}
typealias ColorizeMode = Options<EnumColorizeMode>

//
// Colorize outside
//
// Outside colorization of a fractal
//
enum EnumColorizeOutside: Int, CaseIterable {
    case simple             // No 3D rendering
    case simple3d           // Simple 3D shading
    case blinnPhong         // Blinn-Phong 3D shading
    case filaments          // Draw filaments
}
typealias ColorizeOutside = Options<EnumColorizeOutside>

//
// Colorize inside
//
// Inside colorization of a fractal
//
enum EnumColorizeInside: Int, CaseIterable {
    case simple             // Inside of Mandelbrot set is set to default color
    case orbits             // Colorize orbits inside Mandelbrot set, implies full orbit detection
    case distance           // Colorize distance inside Mandelbrot set, implies distance calculation
}
typealias ColorizeInside = Options<EnumColorizeInside>

//
// Color Palette Mode
//
// Specifies how iteration results are mapped to a color table
//
// Only used when ColorizeMode = .iterations
//
enum EnumPaletteMode: Int, CaseIterable {
    case linear           = 0   // linear color mapping
    case modulo           = 1   // color mapping by modulo division
    case hue              = 2
    case huedyn           = 3
    case lchdyn           = 4
    case histogram        = 5   // Histogram color mapping
    case inverseHistogram = 6
    case cycling          = 7
}
typealias PaletteMode = Options<EnumPaletteMode>

//
// Colormapping parameters
//
struct MandelbrotColoring: FractalParameters {
    var colorizeMode = ColorizeMode(.iterations)    // Colorize mode: iterations, distance, potential, steps, stripes
    var colorizeOutside = ColorizeOutside(.simple)  // Colorize outside: simple, simple3D, blinnPhong
    var colorizeInside = ColorizeInside(.simple)    // Colorize inside: simple, orbits, distance
    var paletteMode = PaletteMode(.linear)          // Palette assignment mode: linear, modulo, hue, huedyn, lchdyn
    var stripes: Int = 0                            // Stripe density, frequency for stripe average coloring
                                                    // Range 0-32, 0 = No stripes, default = 0
    var stripeSig: Double = 0.9                     // Memory parameter for stripe average coloring
                                                    // Range 0-1, 0 = No stripes, default = 0.9
    var steps: Int = 0                              // Step density, frequency for step coloring
                                                    // Range 0-100, 0 = No steps, default = 0
    var ncycle: Double = 1.0                        // Color cycling, must not be 0
}

