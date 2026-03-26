//
//  ColorMapping.swift
//  SwiFractal
//
//  Created by Dirk Braner on 24.11.24.
//

import Foundation
import Numerics
import Accelerate

//
// Colorize Mode
//
// Specifies the iteration value used to calculate the color
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
    case linear    = 0      // linear color mapping
    case modulo    = 1      // color mapping by modulo division
    case hue       = 2
    case huedyn    = 3
    case lchdyn    = 4
    case histogram = 5
    case cycling   = 6
}
typealias PaletteMode = Options<EnumPaletteMode>

//
// Color Mapping and color related parameters
//
struct ColorMapping : FractalParameters {
    
    // Dictionary with color tables
    static var colorTables: [String: ColorTable] = [
        "Grey": ColorTable.grey,
        "Sinus": ColorTable.sinus
    ]
    
    static let defaultValues: [String: Any] = [
        "colorTable":       "Grey",
        "colorizeMode":     "iterations",
        "colorizeOutside":  "simple",
        "colorizeInside":   "simple",
        "paletteMode":      "linear",
        "stripes":          0 as Int,
        "stripeSig":        0.9 as Double,
        "steps":            0 as Int,
        "ncycle":           1.0 as Double,
        "defaultColor":     RGBAColor.defaultValues as [String : Any]
    ]
    
    var colorTable: String = "Grey"                  // Color table name
    var colorizeMode = ColorizeMode(.iterations)          // Colorize mode: iterations, distance, potential, steps, stripes
    var colorizeOutside = ColorizeOutside(.simple)    // Colorize outside: simple, simple3D, blinnPhong
    var colorizeInside = ColorizeInside(.simple)      // Colorize inside: simple, orbits, distance
    var paletteMode = PaletteMode(.linear)       // Palette assignment mode: linear, modulo, hue, huedyn, lchdyn
    var stripes: Int = 0                       // Stripe density, frequency for stripe average coloring
                                            // Range 0-32, 0 = No stripes, default = 0
    var stripeSig: Double = 0.9                  // Memory parameter for stripe average coloring
                                            // Range 0-1, 0 = No stripes, default = 0.9
    var steps: Int = 0                          // Step density, frequency for step coloring
                                            // Range 0-100, 0 = No steps, default = 0
    var ncycle: Double = 1.0                      // Color cycling
    
    // Default color if paletteMode is not .linear or .modulo
    var defaultColor = RGBAColor.black
    
    /// Return color table
    var palette: ColorTable {
        return ColorMapping.colorTables[colorTable, default: ColorTable.grey]
    }
    
    /// Default color defined in color table
    var defColor: RGBAColor {
        return paletteMode.isAny(of: [.linear, .modulo]) ? palette.defColor : defaultColor
    }
    
    /// Number of available colors
    var colorCount: Int {
        return palette.count
    }
    
    /// Return color table entry or default color
    subscript(_ index: Int) -> RGBAColor {
        guard index >= 0, index < colorCount else { return defColor }
        return palette[index]
    }
    
    /// Return palette entry by index
    func getColor(_ index: Int) -> RGBAColor {
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
    
    /// Shading
    func shading(_ cycleIter: Double, _ distance: Double, _ stripeAvg: Double, _ brightness: Double) -> RGBAColor {
        let pLen = Double(colorCount-1)
        var bright = brightness
        
        // Cycle through palette
        var palIndex: Int = Int(round(cycleIter * pLen))
        
        // Distance estimation: log transform and sigmoid on [0,1] => [0,1]
        var dist = Double(-log(distance) / 12)
        dist = 1.0 / (1 + exp(-10 * ((2 * dist - 1) / 2)))
        
        // Shaders: steps and/or stripes
        var nshader: Double = 0
        var shader: Double = 0
        
        // Stripe shading
        if stripeAvg > 0 {
            nshader += 1
            shader += stripeAvg
        }
        
        // Step shading
        if colorizeMode == .steps {
            // Color update: constant color on each major step
            var steps2 = 1.0/Double(steps)
            palIndex = Int(round((cycleIter - cycleIter % steps2) * pLen))

            // Major step: step_s frequency
            var x: Double = cycleIter % steps2 / steps2
            let lightStep1: Double = 6 * (1 - pow(x, 5) - pow((1 - x), 100)) / 10

            // Minor step: n for each major step
            steps2 /= 8
            x = cycleIter % steps2 / steps2
            let lightStep2 = 6 * (1 - pow(x, 5) - pow((1 - x), 30)) / 10

            // Overlay merge between major and minor steps
            let lightStep = ColorMapping.overlay(lightStep2, lightStep1, 1)
            nshader += 1
            shader += lightStep
        }
        
        // Applying shaders to brightness
        if nshader > 0 {
            bright = ColorMapping.overlay(brightness, shader/nshader, 1) * (1-dist) + dist * brightness
        }
        
        var color = getColor(palIndex)
        color.overlay(bright, 1)
        
        return color
    }
    
    func mapColorValue(_ iterations: Double, _ maxIterations: Int, _ nZ: Double, _ normal: Cplx, _ distance: Double, _ potential: Double, _ stripeAvg: Double, _ lightning: Lightning) -> RGBAColor {
        // Reduce palette lenght by 1 for indexing
        let pLen = Double(colorCount) - 1
        
        // The brightness 0..1
        var brightness: Double = 1.0
        
        // The resulting color
        var color = defColor
        
        // Color cycling
        // cycle_iter in range 0..1 (floating point modulo!)
        let cycleIter = (sqrt(iterations) % ncycle) / ncycle
        
        let di = iterations / Double(maxIterations)
        
        // 3D shading, calculate brightness
        if colorizeOutside.isAny(of: [.blinnPhong, .simple3d]) {
            // Normal vector
            let absNormal = normal / normal.length
            let vecNormal = Vector(absNormal.real, absNormal.imaginary, 1.0)
            
            // Simple 3D shading
            if colorizeOutside == .simple3d {
                brightness = lightning.simple3D(vecNormal)
            }
            
            // Blinn Phong 3D shading
            else if colorizeOutside == .blinnPhong {
                brightness = lightning.blinnPhong(vecNormal)
            }
        }

        let fBrightness = Float(brightness)

        // Color based on stripes or steps. colorize and palette mode do not matter here
        if colorizeMode.isAny(of: [.steps, .stripes]) {
            // shading(palette, cycle_iter, dist, colorPar, bright)
            color = shading(cycleIter, distance, stripeAvg, brightness)
        }
        
        // Color based on iterations
        else if colorizeMode == .iterations {
            
            // Linear mapping
            if paletteMode == .linear {
                color = getColor(Int(di * pLen)) * fBrightness
            }
            
            // Modulo division mapping
            else if paletteMode == .modulo {
                color = getColor(Int(di * pLen) % Int(ncycle)) * fBrightness
            }
            
            // Color cycling mapping
            else if paletteMode == .cycling {
                color = getColor(Int(round(cycleIter * pLen))) * fBrightness
            }
            /*
            else if paletteMode == .hue {
                color = hsb2rgb(P[0,0], P[0,1], bright)
            }
             */
            
            // Hue dynamic mapping
            else if paletteMode == .huedyn {
                let h = Double(Int(pow((iterations) * 360, 1.5)) % 360)
                // For hsl model saturation must be set to 0.5
                color = RGBAColor(HSB(Float(h/360), 1.0, fBrightness))
            }
            
            // Lch dynamic mapping
            else if paletteMode == .lchdyn {
                let cpidi = cos(Double.pi * di)
                let v = 1.0 - cpidi * cpidi
                let lch = LCH(Float(75.0 - (75.0 * v)), Float(28.0 + (75.0 - (75.0 * v))), Float(pow(360.0 * di, 1.5) % 360.0))
                color = RGBAColor(lch) * fBrightness
            }
        }
        
        // Color based on distance
        else if colorizeMode == .distance {
            color = getColor(Int(tanh(distance) * pLen)) * fBrightness
        }
        
        // Color based on potential
        else if colorizeMode == .potential {
            let lognZ12 = log(nZ) / 2.0
            let nu = log(lognZ12 / _NC.LOG2) / _NC.LOG2
            let i = iterations + 1.0 - nu
            let color1 = getColor(Int(i))
            let color2 = getColor(Int(i) + 1)
            let ic: Double = i % 1.0
            let cv = vDSP.linearInterpolate(color1.vector3, color2.vector3, using: ic)
            color = RGBAColor(cv) * fBrightness
        }
        /*
         exponentially / cyclic color mapping
         
         Int(pow(pow(iterations / Double(MP.iterations), 2.0) * Double(colorCount), 1.5)) % colorCount
         */

        // Return color with gamma correction
        return color.gammaCorrection(lightning.parameters.gamma)
    }
}
