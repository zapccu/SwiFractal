//
//  MandelbrotColorMapper.swift
//  SwiFractal
//
//  Created by Dirk Braner on 05.07.26.
//

import Foundation
import Accelerate


/// Colormapper
struct ColorMapper : Sendable {
    
    /// Static color table for coloring the interior of the Mandelbrot set based on orbit length
    let category10 = ColorTableStatic("Category10",
        colors: [0x1f77b4, 0xff7f0e, 0x2ca02c, 0xd62728, 0x9467bd, 0x8c564b, 0xe377c2, 0x7f7f7f, 0xbcbd22, 0x17becf],
        defColor: .black
    )
    
    /// Copy of fractal color parameters
    let colorParameters: FractalColorParameters
    
    /// Copy of fractal calculation limits
    let limits: FractalLimits
    
    /// Copy of histogram of current image
    let histogram: Histogram
    
    /// Copy of precalculated fractal lightning parameters
    let lightning: Lightning
    
    /// Coloring type
    var coloring: any Coloring { colorParameters.coloring.coloringType }
    
    /// Square root of ncycle. Defines how many iterations correlate with 1 cycle.
    let sqrtncycle: Double
    
    /// Initialize colormapper
    init(colorParameters: FractalColorParameters, limits: FractalLimits, histogram: Histogram, lightning: Lightning) {
        self.colorParameters = colorParameters
        self.limits = limits
        self.histogram = histogram
        self.lightning = lightning
        self.sqrtncycle = sqrt(max(colorParameters.ncycle, 1))
    }
    
    /// Compress smooth iteration value to prevent frequent color changes near Mandelbrot set.
    /// Compression level is defined in colorParameters.compression as n-th root of smoothIter.
    /// 1 = no compression, 2 = square root (default)
    /// - Parameter smoothIter: Smooth iteration counter in range 1...MaxIter
    /// - Returns: Compressed smooth iteration counter.
    @inline(__always)
    func compress(smoothIter: Double) -> Double {
        let compression = Double(max(colorParameters.compression, 1))
        guard compression > 1 else { return smoothIter }    // No compression
        
        if compression == 2 { return sqrt(smoothIter) }
        if compression == 3 { return cbrt(smoothIter) }
        return pow(smoothIter, 1.0 / compression)
    }
    
    /// Color cycling
    /// - Parameters:
    ///   - smoothIter: Smooth iteration value in range 1...MaxIter. Usually result of *compress()*
    ///   - scale: Frequency of color changing
    ///   - offset: Offset to first value in color table
    ///   Modulo division by *sqrtncycle* allows to determine after how many (transformed) iteration steps the color repeats,
    ///   regardless of the absolute iteration depth. 1 = Full color cycle every 1 iteration (default).
    ///   *sqrtncycle* must be > 0.
    /// - Returns: Smooth iteration counter in range 0...1
    ///
    /// **About scale**
    ///
    /// **Effects on iterations**
    ///
    /// Scale =  0.01 - 1:\
    /// It takes 1/scale iterations to get from one color to next color in color table.
    ///
    /// Scale = 1 - 50:\
    /// Within 1 iteration step palette is passed through *scale* times.
    ///
    /// **Effects on coloring**
    ///
    /// Scale = 0.01 - 0.1:\
    /// Colors are changing very slowly. Glowing effect around Mandelbrot set. Wide color areas, no color ring effects.
    /// Useful for deep zooms with rapidly changing iteration values.
    ///
    /// Scale = 2.0 - 20.0:\
    /// Ring structures. Detailed structures close to Mandelbrot set are better visible.
    ///
    /// Scale = 20.0 - 50.0:\
    /// Moire effects. 3D looks.
    @inline(__always)
    func cycle(smoothIter: Double, scale: Double = 1.0, offset: Double = 0.0) -> Double {
        return (fmod(smoothIter * scale + offset, sqrtncycle) / sqrtncycle)
    }
    
    @inline(__always)
    func smoothstep(_ e0: Double, _ e1: Double, _ x: Double) -> Double {
        let u = min(max((x - e0) / (e1 - e0), 0.0), 1.0)
        return u * u * (3.0 - 2.0 * u)
    }

    /// Shading
    /// - Parameters:
    ///   - cycleIter: Smooth iteration value in range 0...1. Usually result of *cycle()*
    ///   - logPixelDistance: Logarithm of distance to Mandelbrot set
    ///   - stripeAvg: Stripe average value
    ///   - brightness: Brightness. Either 1.0 or the result of *shading3D()*
    /// - Returns: Tuple (color, brightness)
    func shading(cycleIter: Double, logPixelDist: Double, stripeAvg: Double, brightness: Float) -> (RGBAColor, Float) {
        let blending: EnumBlendingMode = .hardLight
        
        var bright = brightness
        var color = coloring.defColor
        var virtualIndex = cycleIter

        // Calculate smooth edge detector. Used to suppress shader effects near the boundary of
        // the Mandelbrot set.
        //let distD = -logDistance / 12.0
        //let dist = Float(1.0 / (1 + exp(-10 * (distD - 0.5))))
        let midPixels = 3.0                       // ab dieser Distanz in Pixeln wird ausgeblendet
        let dist = Float(1.0 / (1 + exp(10.0 / 12.0 * (logPixelDist - log(midPixels)))))
        
        // Shaders: steps and/or stripes
        var nshader: Float = 0
        var shader: Float = 0
        
        // Stripe shading
        if stripeAvg > 0 {
            nshader += 1
            shader += Float(stripeAvg)
        }
        
        // Step shading
        if colorParameters.colorizeMode == .steps {
            // Color update: constant color on each major step
            var steps2 = 1.0 / Double(colorParameters.steps)
            virtualIndex = cycleIter - fmod(cycleIter, steps2)

            // Major step: step_s frequency
            var x = Float(fmod(cycleIter, steps2) / steps2)
            let lightStep1: Float = 6 * (1 - pow(x, 5) - pow((1 - x), 100)) / 10
            
            // Minor step: 8 for each major step
            steps2 /= 8
            x = Float(fmod(cycleIter, steps2) / steps2)
            let lightStep2: Float = 6 * (1 - pow(x, 5) - pow((1 - x), 30)) / 10
            
            // Overlay merge between major and minor steps
            let lightStep = blending.blend(base: lightStep2, top: lightStep1)
            nshader += 1
            shader += lightStep
        }
        
        // Applying shaders to brightness
        if nshader > 0 {
            bright = blending.blend(base: Float(bright), top: Float(shader/nshader)) * (1.0 - dist) + dist * bright
        }
        
        color = coloring.getColor(vindex: virtualIndex)
        return (color, Float(bright))
    }
    
    /// 3D shading
    /// - Parameter normal: Last Z / D
    /// - Returns: Brightness value greater than or equal to 0.0
    func shading3D(normal: Cplx) -> Float {
        var brightness: Float = 1.0
        
        // Normal vector
        let absNormal = normal / normal.length
        let vecNormal: Vector<Double> = [absNormal.real, absNormal.imaginary, 1.0]
        
        // Simple 3D shading
        if colorParameters.colorizeOutside == .simple3d {
            brightness = lightning.simple3D(vecNormal)
        }
        
        // Blinn Phong 3D shading
        else if colorParameters.colorizeOutside == .blinnPhong {
            brightness = lightning.blinnPhong(vecNormal, blending: lightning.blendingMode)
        }
        
        return brightness
    }
    
    /// Map color based on result flags
    /// - Parameter result: Mandelbrot result
    /// - Returns: Color or nil
    func mapFlags(result: MandelbrotResult) -> RGBAColor? {
        if result.flags.isSubset(of: [.defaultColor, .maxIterations, .error, .calculate]) {
            return coloring.defColor
        }
        else if result.flags == .inside {
            switch colorParameters.colorizeInside() {
            case .defaultColor, .fastOrbits:
                return coloring.defColor
            case .distance:
                return coloring.getColor(t: result.distance)
            case .orbits:
                let index = Int(result.distance) % category10.count
                let color = category10[index]
                let brightness = Float(pow(0.7, result.smoothIter / 100.0))
                return color.blend(with: brightness, mode: .multiply)
            }
        }
        
        return nil
    }
    
    /// Map Mandelbrot iteration result to color
    /// - Parameters:
    ///   - result: Mandelbrot iteration result
    ///   - P: Mandelbrot dynamic calculation parameters
    /// - Returns: Color
    func mapColor(result: MandelbrotResult) -> RGBAColor {
        // The brightness 0...1
        var brightness: Float = 1.0
        
        // Color interior of Mandelbrot set
        if let interiorColor = mapFlags(result: result) {
            return interiorColor
        }
        
        // The resulting color, initialized with default color
        var color: RGBAColor = coloring.defColor
        
        // 3D shading, calculate brightness in range 0...
        if colorParameters.colorizeOutside.isAny(of: [.blinnPhong, .simple3d]) {
            brightness = shading3D(normal: Cplx(result.normalReal, result.normalImag))
        }
        
        // Compress smooth iteration count in range 1...MaxIter
        let compressedIter = compress(smoothIter: result.smoothIter)
        
        // Cycle colors
        let cycleIter = cycle(smoothIter: compressedIter, scale: colorParameters.scale, offset: colorParameters.offset)

        //
        // Calculate color based on colorize mode
        //
        
        // Shading. Coloring based on stripes and/or steps. colorize mode and palette mode do not matter here
        if colorParameters.colorizeMode.isAny(of: [.steps, .stripes]) {
            (color, brightness) = shading(cycleIter: cycleIter, logPixelDist: result.distance, stripeAvg: result.stripeAvg, brightness: brightness)
        }
        
        // Color depends on iterations
        else if colorParameters.colorizeMode == .iterations {
            //
            // Color depends on palette mode
            //
            
            // Linear mapping based on color table or calculated colors
            if colorParameters.paletteMode == .linear {
                color = coloring.getColor(iter: Int(result.smoothIter), maxIter: limits.iterations)
            }
            
            // Interpolated mapping
            else if colorParameters.paletteMode == .interpolated {
                color = coloring.getColor(t: cycleIter)
                //color = coloring.getColor(smoothIter: compressedIter, scale: colorParameters.scale,
               //                           offset: colorParameters.offset, ncycle: colorParameters.ncycle) * brightness
            }
            
            /*
             Todo:
             else if MP.paletteMode == .hue {
             color = hsb2rgb(P[0,0], P[0,1], bright)
             }
             */
            
            // Hue dynamic mapping
            else if colorParameters.paletteMode == .huedyn {
                let h = Double(Int(pow((result.smoothIter * 360.0), 1.5)) % 360)
                // For hsl model saturation must be set to 0.5
                color = RGBAColor(hsb: HSB(Float(h/360), 1.0, brightness))
            }
            
            // Histogram mapping
            else if colorParameters.paletteMode == .histogram {
                if let colorTable = coloring as? (any ColorTable) {
                    let h = histogram.normalize(result)
                    color = colorTable[h]
                }
            }
            
            // Inverse histogram mapping
            else if colorParameters.paletteMode == .inverseHistogram {
                if let colorTable = coloring as? (any ColorTable) {
                    let h = 1.0 - histogram.normalize(result)
                    color = colorTable[h]
                }
            }
        }
        
        // Color based on distance
        else if colorParameters.colorizeMode == .distance {
            color = coloring.getColor(t: cycleIter)
            if result.distance.isFinite {
                let minBrightness: Double = 0.2
                let edge = smoothstep(-1.0, 1.5, result.distance)       // 0 am Rand, 1 weit weg
                let k = Float(minBrightness + (1.0 - minBrightness) * edge)
                return color.scaleRGB(by: k)
            }
        }
        
        // Draw filaments
        // TODO: Make the filament color configurable
        if colorParameters.colorizeOutside == .filaments {
            color = RGBAColor.lerpExact(from: color, to: RGBAColor(0.8, 0.9, 1.0), factor: Float(result.filament))
        }

        // Blending, tone mapping, gamma correction
        return color.blend(with: brightness, lightning: lightning)
    }

    func mapResult(result: any CalculationResult) -> RGBAColor {
        if let result = result as? MandelbrotResult {
            return mapColor(result: result)
        }
        
        return .black
    }
}
