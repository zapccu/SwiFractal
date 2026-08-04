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
    
    let coloring: MandelbrotColoring
    let colorTable: EnumColorTable
    let limits: MandelbrotLimits
    let pLen: Double                    // Number of colors in palette - 1
    let histogram: Histogram
    let lightning: Lightning

    /// Initialize colormapper
    init(coloring: MandelbrotColoring, colorTable: EnumColorTable, limits: MandelbrotLimits,
         histogram: Histogram, lightning: LightningParameters) {
        self.coloring = coloring
        self.colorTable = colorTable
        self.limits = limits
        self.histogram = histogram
        self.lightning = Lightning(lightning)
        
        // Reduce palette lenght by 1 for index between 0 and count-1
        self.pLen = Double(colorTable.ct.count - 1)
    }
    
    /// Shading
    func shading(result: MandelbrotResult, _ cycleIter: Double, _ brightness: Double) -> RGBAColor {
        var bright = brightness
        
        // Cycle through palette
        var palIndex: Int = Int(round(cycleIter * pLen))
        
        // Distance estimation: log transform and sigmoid on [0,1] => [0,1]
        var dist = Double(-log(result.distance) / 12)
        dist = 1.0 / (1 + exp(-10 * ((2 * dist - 1) / 2)))
        
        // Shaders: steps and/or stripes
        var nshader: Double = 0
        var shader: Double = 0
        
        // Stripe shading
        if result.stripeAvg > 0 {
            nshader += 1
            shader += result.stripeAvg
        }
        
        // Step shading
        if coloring.colorizeMode == .steps {
            // Color update: constant color on each major step
            var steps2 = 1.0/Double(coloring.steps)
            palIndex = Int(round((cycleIter - cycleIter % steps2) * pLen))
            
            // Major step: step_s frequency
            var x: Double = cycleIter % steps2 / steps2
            let lightStep1: Double = 6 * (1 - pow(x, 5) - pow((1 - x), 100)) / 10
            
            // Minor step: n for each major step
            steps2 /= 8
            x = cycleIter % steps2 / steps2
            let lightStep2 = 6 * (1 - pow(x, 5) - pow((1 - x), 30)) / 10
            
            // Overlay merge between major and minor steps
            let lightStep = BlendingMode.hardLight.blend(base: lightStep2, top: lightStep1)
            nshader += 1
            shader += lightStep
        }
        
        // Applying shaders to brightness
        if nshader > 0 {
            bright = BlendingMode.hardLight.blend(base: brightness, top: shader/nshader) * (1 - dist) + dist * brightness
            //bright = BlendingMode.overlay(gamma: 1).blend(brightness, shader/nshader) * (1-dist) + dist * brightness
            //bright = hardLight(bright, shader/nshader) * (1 - dist) + dist * bright
        }
        
        var color = colorTable.ct[palIndex]
        color.hardLight(top: Float(bright))
        
        return color
    }
    
    /// Map Mandelbrot iteration result to color
    /// - Parameters:
    ///   - result: Mandelbrot iteration result
    ///   - P: Mandelbrot dynamic calculation parameters
    /// - Returns: Color
    func mapColor(result: MandelbrotResult) -> RGBAColor {
        // The brightness 0-1
        var brightness: Double = 1.0
        
        // The resulting color, initialized with default color
        var color = colorTable.ct.defColor
        
        // Check condition for default color
        if (result.flags.isSubset(of: [.defaultColor, .maxIterations, .error])) {
            return color
        }
        
        // Step width between iterations 0-1
        let di = result.smoothIter / Double(limits.iterations)
        
        // 3D shading, calculate brightness
        if coloring.colorizeOutside.isAny(of: [.blinnPhong, .simple3d]) {
            // Normal vector
            let normal = Cplx(result.normalReal, result.normalImag)
            let absNormal = normal / normal.length
            let vecNormal: Vector<Double> = [absNormal.real, absNormal.imaginary, 1.0]
            
            // Simple 3D shading
            if coloring.colorizeOutside == .simple3d {
                brightness = lightning.simple3D(vecNormal)
            }
            
            // Blinn Phong 3D shading
            else if coloring.colorizeOutside == .blinnPhong {
                brightness = lightning.blinnPhong(vecNormal)
            }
        }
        
        let fBrightness = Float(brightness)
        
        // Color based on stripes and/or steps. colorize mode and palette mode do not matter here
        if coloring.colorizeMode.isAny(of: [.steps, .stripes]) {
            // Color cycling. cycle_iter is in range 0-1 (% = floating point modulo division!)
            let cycleIter = (sqrt(result.smoothIter) % coloring.ncycle) / coloring.ncycle
            
            // Shading
            color = shading(result: result, cycleIter, brightness)
        }
        
        // Color based on iterations
        else if coloring.colorizeMode == .iterations {
            // Linear mapping
            if coloring.paletteMode == .linear {
                color = colorTable.ct[di, fBrightness]
            }
            
            // Modulo division mapping (integer modulo division)
            else if coloring.paletteMode == .modulo {
                color = colorTable.ct[Int(di * pLen) % Int(coloring.ncycle), fBrightness]
            }
            
            // Color cycling mapping
            else if coloring.paletteMode == .cycling {
                // Color cycling. cycle_iter in range 0-1 (floating point modulo division!)
                let cycleIter = (sqrt(result.smoothIter) % coloring.ncycle) / coloring.ncycle
                color = colorTable.ct[round(cycleIter * pLen), fBrightness]
            }
            /*
             Todo:
             else if MP.paletteMode == .hue {
             color = hsb2rgb(P[0,0], P[0,1], bright)
             }
             */
            
            // Hue dynamic mapping
            else if coloring.paletteMode == .huedyn {
                let h = Double(Int(pow((result.smoothIter * 360.0), 1.5)) % 360)
                // For hsl model saturation must be set to 0.5
                color = RGBAColor(HSB(Float(h/360), 1.0, fBrightness))
            }
            
            // Lch dynamic mapping
            else if coloring.paletteMode == .lchdyn {
                let cosPiDi = cos(Double.pi * di)
                let v = 1.0 - cosPiDi * cosPiDi
                let lch = LCH(Float(75.0 - (75.0 * v)), Float(28.0 + (75.0 - (75.0 * v))), Float(pow(360.0 * di, 1.5) % 360.0))
                color = RGBAColor(lch) * fBrightness
            }
            
            // Histogram mapping
            else if coloring.paletteMode == .histogram {
                let h = histogram.normalize(result)
                color = colorTable.ct[Int(h * pLen), fBrightness]
            }
            
            // Inverse histogram mapping
            else if coloring.paletteMode == .inverseHistogram {
                let h = 1.0 - histogram.normalize(result)
                color = colorTable.ct[Int(h * pLen), fBrightness]
            }
        }
        
        // Color based on distance
        else if coloring.colorizeMode == .distance {
            color = colorTable.ct[tanh(result.distance), fBrightness]
        }
        
        // Color based on potential
        else if coloring.colorizeMode == .potential {
            let lognZ12 = log(result.nZ) / 2.0
            let nu = log(lognZ12 / _NC.LOG2) / _NC.LOG2
            let i = result.smoothIter + 1.0 - nu
            let color1 = colorTable.ct[i]
            let color2 = colorTable.ct[i + 1]
            let ic: Double = i % 1.0
            let cv = vDSP.linearInterpolate(color1.vector3, color2.vector3, using: ic)
            color = RGBAColor(cv) * fBrightness
        }
        
        // Draw filaments
        // TODO: Make the filament color configurable
        if coloring.colorizeOutside == .filaments {
            color.mix(with: RGBAColor(0.8, 0.9, 1.0), factor: Float(result.filament))
        }
        
        // Return color with gamma correction
        return color.gammaCorrection(lightParameters.gamma)
    }
}
