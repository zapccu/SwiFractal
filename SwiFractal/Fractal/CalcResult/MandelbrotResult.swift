//
//  MandelbrotResult.swift
//  SwiFractal
//
//  Created by Dirk Braner on 05.05.26.
//

import Foundation

//
// Mandelbrot calculation result
//
struct MandelbrotResult<DP: DynamicParameters> : CalculationResult {
    
    enum Flags: UInt8 {
        case defaultColor = 0   // assign default color, no color mapping
        case maxIterations = 1  // max. iterations reached
        case bailout = 2        // bailout reached
        case inside = 4         // smoothIter contains orbit length
        case error = 8          // error during calculation
    }
    
    // Result values
    var smoothIter: Double = 0.0        // Smooth iteration counter
    var nZ: Double = 0.0
    var normalReal: Double = 0.0
    var normalImag: Double = 0.0
    var distance: Double = 0.0          // Distance to Mandelbrot set
    var potential: Double = 0.0         // Potential
    var stripeAvg: Double = 0.0         // Stripe average
    var flags: Flags = .defaultColor
    
    static let zero: MandelbrotResult = MandelbrotResult()
    static let defaultValue: MandelbrotResult = MandelbrotResult()
    
    /// Shading
    func shading(P: DP, _ cycleIter: Double, _ brightness: Double) -> RGBAColor {
        let pLen = Double(P.colorTable.ct.count - 1)
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
        if P.MP.colorizeMode == .steps {
            // Color update: constant color on each major step
            var steps2 = 1.0/Double(P.MP.steps)
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
        
        var color = P.colorTable.ct[palIndex]
        color.hardLight(top: Float(bright))
        
        return color
    }
    
    // Map color value
    func mapColorValue(P: MandelbrotDynamicParameters<RT>) -> RGBAColor {
        // Reduce palette lenght by 1 for index between 0 and count-1
        let pLen = Double(P.colorTable.ct.count-1)
        
        // The brightness 0-1
        var brightness: Double = 1.0
        
        // The resulting color
        var color = P.colorTable.ct.defColor
        
        let di = smoothIter / Double(P.MP.iterations)
        
        // Filaments
        if bFilaments {
            let edgeWidth = (RT(distance, precision: P.MP.common.prec) / P.dx).toDouble()
            if edgeWidth < 1.0 {
                // We are close to the Mandelbrot set -> Draw sharp black filament
                // Use (1.0 - edgeWidth) for simple anti aliasing
                let intensity = edgeWidth // 0.0 = Black (mitten drauf), 1.0 = Background
                return RGBAColor(grey: intensity)
            }
        }
        
        // 3D shading, calculate brightness
        if P.MP.colorizeOutside.isAny(of: [.blinnPhong, .simple3d]) {
            // Normal vector
            let absNormal = normal / normal.length
            let vecNormal: Vector<Double> = [absNormal.real, absNormal.imaginary, 1.0]
            
            // Simple 3D shading
            if MP.colorizeOutside == .simple3d {
                brightness = lightning.simple3D(vecNormal)
            }
            
            // Blinn Phong 3D shading
            else if MP.colorizeOutside == .blinnPhong {
                brightness = lightning.blinnPhong(vecNormal)
            }
        }

        let fBrightness = Float(brightness)

        // Color based on stripes or steps. colorize and palette mode do not matter here
        if P.MP.colorizeMode.isAny(of: [.steps, .stripes]) {
            // Color cycling
            // cycle_iter in range 0..1 (floating point modulo!)
            let cycleIter = (sqrt(smoothIter) % P.MP.ncycle) / P.MP.ncycle
            
            color = shading(P: P, cycleIter, brightness)
        }
        
        // Color based on iterations
        else if P.MP.colorizeMode == .iterations {
            switch P.MP.paletteMode {
            case .linear:
                color = P.colorTable.ct[di, fBrightness]
            case .modulo:
                color = P.colorTable.ct[Int(di * pLen) % Int(MP.ncycle), fBrightness]
            case .cycling:
                // cycle_iter in range 0..1 (floating point modulo!)
                let cycleIter = (sqrt(smoothIter) % MP.ncycle) / MP.ncycle
                color = P.colorTable.ct[round(cycleIter * pLen), fBrightness]
            }
            // Linear mapping
            if P.MP.paletteMode == .linear {
                color = P.colorTable.ct[di, fBrightness]
            }
            
            // Modulo division mapping
            else if P.MP.paletteMode == .modulo {
                color = P.colorTable.ct[Int(di * pLen) % Int(MP.ncycle), fBrightness]
            }
            
            // Color cycling mapping
            else if P.MP.paletteMode == .cycling {
                // Color cycling
                // cycle_iter in range 0..1 (floating point modulo!)
                let cycleIter = (sqrt(smoothIter) % MP.ncycle) / MP.ncycle
                color = P.colorTable.ct[round(cycleIter * pLen), fBrightness]
            }
            /*
            else if MP.paletteMode == .hue {
                color = hsb2rgb(P[0,0], P[0,1], bright)
            }
             */
            
            // Hue dynamic mapping
            else if P.MP.paletteMode == .huedyn {
                let h = Double(Int(pow((iterations) * 360, 1.5)) % 360)
                // For hsl model saturation must be set to 0.5
                color = RGBAColor(HSB(Float(h/360), 1.0, fBrightness))
            }
            
            // Lch dynamic mapping
            else if MP.paletteMode == .lchdyn {
                let cpidi = cos(Double.pi * di)
                let v = 1.0 - cpidi * cpidi
                let lch = LCH(Float(75.0 - (75.0 * v)), Float(28.0 + (75.0 - (75.0 * v))), Float(pow(360.0 * di, 1.5) % 360.0))
                color = RGBAColor(lch) * fBrightness
            }
        }
        
        // Color based on distance
        else if P.MP.colorizeMode == .distance {
            color = P.colorTable.ct[tanh(distance), fBrightness]
        }
        
        // Color based on potential
        else if P.MP.colorizeMode == .potential {
            let lognZ12 = log(nZ) / 2.0
            let nu = log(lognZ12 / _NC.LOG2) / _NC.LOG2
            let i = iterations + 1.0 - nu
            let color1 = P.colorTable.ct[i]
            let color2 = P.colorTable.ct[i + 1]
            let ic: Double = i % 1.0
            let cv = vDSP.linearInterpolate(color1.vector3, color2.vector3, using: ic)
            color = RGBAColor(cv) * fBrightness
        }

        // Return color with gamma correction
        return color.gammaCorrection(P.lightning.parameters.gamma)
    }
    
    func mapColorValue(result: MandelbrotResult) -> RGBAColor {
        if result.flags == .bailout {
            return self.mapColorValue(result.smoothIter, result.nZ, Cplx(result.normalReal, result.normalImag), result.distance, result.potential, result.stripeAvg)
        }
        else {
            return colorTable.ct.defColor
        }
    }
        
}



