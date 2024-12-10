//
//  Mandelbrot.swift
//  SwiFractal
//
//  Created by Dirk Braner on 20.11.24.
//

import SwiftUI
import Numerics

//
// Class for Mandelbrot calculation parameters
//
class MandelbrotParameters: FractalParameters {
    // Constant parameters
    var corner: Cplx,
        size: Cplx,
        iterations: Int,
        stripes: Int,                   // Stripe density
        stripeSig: Double,
        steps: Int,                     // Step density
        colorMapping: ColorMapping

    // Parameters calculated or modified based on constant parameters
    var bailout: Double,                // Bailout radius
        ncycle: Double,
        diaScale: Double,
        diag: Double
    
    // Flags
    var bStripes: Bool,                 // Draw stripes
        bSteps: Bool,                   // Draw steps
        bDist: Bool,                    // Calculate distance to Mandelbrot set
        bOrbits: Bool,                  // Draw orbits
        bShading: Bool                  // Either simple3D or blinnPhong
    
    /// Initialize Mandelbrot calculation parameters
    ///
    /// Parameters:
    ///
    /// parameterset: Mandelbrot parameterset
    ///
    override init(_ parameterset: ParameterSet = ParameterSet()) {
        // Constant parameters
        corner       = parameterset["corner", Cplx(-2.25,-1.5)]
        size         = parameterset["size", Cplx(3,3)]
        iterations   = parameterset["iterations", 500]
        stripes      = parameterset["stripes", 0]
        stripeSig    = 0.9
        steps        = parameterset["steps", 0]
        ncycle       = parameterset["ncycle", 1]
        colorMapping = ColorMapping(parameterset)

        // Parameters
        diag      = size.length
        bailout   = colorMapping.colorizeMode == .iterations && colorMapping.paletteMode != .hue && colorMapping.colorizeOptions == .simple ? 4.0 : pow(10, 10)
        ncycle    = sqrt(ncycle)
        diaScale  = Double(iterations) / 10.0
        
        // Flags
        bStripes = stripes > 0
        bSteps   = steps > 0
        bOrbits  = colorMapping.colorizeOptions && .orbits
        bDist    = colorMapping.colorizeMode == .distance || bStripes || bSteps
        bShading = colorMapping.colorizeOptions && .shading
        
        // Stripes and steps require shading
        if (bStripes || bSteps) && !bShading {
            colorMapping.colorizeOptions |= .blinnPhong
            bShading = true
        }
        
        // Initialize common fractal calculation parameters
        super.init(parameterset)
    }

}

class Mandelbrot: Fractal {
    
    // Return fractal type
    override var fractalType: String { return "Mandelbrot" }
    
    // Mandelbrot set calculation parameters
    var MP: MandelbrotParameters = MandelbrotParameters()
    
    // 2 dimensional array with complex coordinates
    var cplxGrid: [[Cplx]] = []
    
    // Count orbits found during calculation
    var orbitCount: Int = 0
    
    /// Initialize Mandelbrot object
    override init(_ dict: DictPar = [:]) {
        // Add default settings for Mandelbrot set
        // Settings are part of common fractal class
        super.init([
            "corner": Cplx(-2.25, -1.5), "size": Cplx(3.0, 3.0),
            "iterations": 500,
            "stripes": 0,           // Stripe density 0..32
            "steps": 0,             // Step density 0..100
            "ncycle": 1.0,          // Color cycling 0..200
            "colorTable": ColorTable.greyScale,
            "paletteMode": PaletteMode.linear,
            "colorizeMode": ColorizeMode.iterations,
            "colorizeOptions": ColorizeOptions.simple
        ])
        
        // Add settings of child classes
        settings.addSettings(dict)
        
        // Create default calculation parameters
        MP = MandelbrotParameters(settings)
    }
    
    func beginCalculation(_ width: Int, _ height: Int) {
        MP = MandelbrotParameters(settings)
        cplxGrid = mapScreenCoordinates(width, height)
        orbitCount = 0
        super.beginCalculation()
    }
    
    override func endCalculation() {
        super.endCalculation()
        print("orbitCount: \(orbitCount)")
    }
    
    func adjustAspectRatio(_ imageWidth: Int, _ imageHeight: Int, _ corner: Cplx, _ size: Cplx) -> (corner: Cplx, size: Cplx) {
        let imageRatio = Double(imageWidth) / Double(imageHeight)
        let fractalRatio = size.real / size.imaginary
        
        if imageRatio != fractalRatio {
            let fractalHeight = size.real / imageRatio
            let newCorner = Complex(corner.real, corner.imaginary + (size.imaginary - fractalHeight) / 2)
            let newSize = Complex(size.real, fractalHeight)
            return (newCorner, newSize)
        }
        
        return (corner, size)
    }
    
    func mapScreenCoordinates(_ imageWidth: Int, _ imageHeight: Int, _ aspectRatio: Bool = true) -> [[Cplx]] {
        if var corner: Cplx = settings["corner"], var size: Cplx = settings["size"] {
            if aspectRatio {
                (corner, size) = adjustAspectRatio(imageWidth, imageHeight, corner, size)
            }
            
            return linspace(corner, corner+size, imageWidth, imageHeight)
        }
        
        return []
    }
    
    /// Map iteration result to color
    func mapColorValue(_ iterations: Double, _ nZ: Double, _ normal: Cplx, _ distance: Double, _ potential: Double, _ stripeAvg: Double) -> RGBAColor {
        let pLen = Double(MP.colorMapping.colorCount)
        var brightness: Double = 1.0
        var color = MP.colorMapping.defColor
        
        if MP.colorMapping.colorizeOptions && .simple3d {
            let absNormal = normal / Cplx(normal.length)
            let vecNormal = Vector(absNormal.real, absNormal.imaginary, 1.0)
            brightness = MP.lightning.simple3D(vecNormal)
        }
        else if MP.colorMapping.colorizeOptions && .blinnPhong {
            let absNormal = normal / Cplx(normal.length)
            let vecNormal = Vector(absNormal.real, absNormal.imaginary, 1.0)
            brightness = MP.lightning.blinnPhong(vecNormal)
        }

        let fBrightness = Float(brightness)

        if stripeAvg > 0 || MP.steps > 0 {
            color = shading(iterations, distance, stripeAvg, brightness)
        }
        else if MP.colorMapping.colorizeMode == .iterations {
            if MP.colorMapping.paletteMode == .linear {
                color = MP.colorMapping[Int(iterations/Double(MP.iterations) * pLen)] * fBrightness
            }
            else if MP.colorMapping.paletteMode == .modulo {
                color = MP.colorMapping[Int(pLen * iterations/Double(MP.iterations)) % Int(MP.ncycle)] * fBrightness
            }
            /*
            else if MP.colorMapping.paletteMode == .hue {
                color = hsb2rgb(P[0,0], P[0,1], bright)
            }
             */
            else if MP.colorMapping.paletteMode == .huedyn {
                let h = Double(Int(pow((iterations) * 360, 1.5)) % 360)
                // For hsl model saturation must be set to 0.5
                color = RGBAColor(HSB(Float(h/360), 1.0, fBrightness))
            }
            /*
            else if MP.colorMapping.paletteMode == .lchdyn {
                let v = 1.0 - pow(cos(Double.pi * iterations), 2.0)
                // /100, /130
                color = lch2rgb(np.array([(75 - (75 * v)), (28 + (75 - (75 * v))), pow(360 * iterations, 1.5) % 360])) * bright
            }
             */
        }
        else if MP.colorMapping.colorizeMode == .distance {
            color = MP.colorMapping[Int(tanh(distance) * pLen)] * fBrightness
        }
        else if MP.colorMapping.colorizeMode == .potential {
            color = MP.colorMapping[Int(pLen * iterations/Double(MP.iterations))] * fBrightness
        }

        return color.gammaCorrection(MP.lightning.gamma)
    }
    
    /// Shading
    func shading(_ iterations: Double, _ distance: Double, _ stripeAvg: Double, _ brightness: Double) -> RGBAColor {
        let pLen = Double(MP.colorMapping.colorCount-1)
        let steps = Double(MP.steps)
        var bright = brightness
        
        // Cycle through palette
        let nIter: Double = sqrt(iterations) % MP.ncycle / MP.ncycle
        var palIndex: Int = Int(round(nIter * pLen))
        
        // Distance estimation: log transform and sigmoid on [0,1] => [0,1]
        var dist = Double(-log(distance) / 12)
        dist = 1 / (1 + exp(-10 * ((2 * dist - 1)/2)))
        
        // Shaders: steps and/or stripes
        var nshader: Double = 0
        var shader: Double = 0
        
        // Stripe shading
        if stripeAvg > 0 {
            nshader += 1
            shader += stripeAvg
        }
        
        // Step shading
        if MP.steps > 0 {
            // Color update: constant color on each major step
            var steps: Double = 1.0/steps
            palIndex = Int(round((nIter - nIter % steps) * pLen))

            // Major step: step_s frequency
            var x: Double = nIter % steps / steps
            let lightStep1: Double = 6 * (1 - pow(x, 5) - pow((1 - x), 100)) / 10

            // Minor step: n for each major step
            steps /= 8
            x = nIter % steps / steps
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
        
        var color = MP.colorMapping[palIndex]
        color.overlay(bright, 1)
        
        return color
    }
    
    /*
     func findOrbit(_ orbits: [Cplx], _ Z: Cplx, _ tolerance1: Double, _ tolerance2: Double? = nil) -> Int {
     let l = orbits.count
     let e = max(-1, l - 100)
     
     for n in stride(from: l, to: e, by: -1) {
     let d = Z - orbits[n]
     if d.real * d.real + d.imaginary * d.imaginary < tolerance1 {
     if let tolerance = tolerance2 {
     return findOrbit(orbits, Z, tolerance)
     }
     }
     }
     
     return -1
     }
     */
    
    func calculatePointZ2(_ C: Cplx) -> RGBAColor {
        let log2 = log(Double(2))
        
        var distance: Double = 0.0
        var potential: Double = 0.0
        var stripeAvg: Double = 0.0
        var stripet: Double = 0.0
        
        var Z = Cplx(0.0)
        var nZ: Double = 0.0        // Norm of Z: Z.imaginary * Z.imageinary + Z.real * Z.real
        var nZ1: Double = 0.0       // Old value of nZ for fast orbit detection
        var aZ: Double = 0.0        // abs(Z) = sqrt(nZ)
        var period: Int = 0         // Period counter for fast orbit detection
        var D = Cplx(1.0, 0.0)      // 1st derivation of Z
        var smoothIter: Double = 0  // Smooth iteration counter
        
        var orbits = Array<Cplx>(repeating: Cplx(0.0), count: MP.iterations+1)
        
        for i in 0...MP.iterations {
            if MP.bDist || MP.bShading {
                D = D * 2.0 * Z + 1.0
            }
            
            Z = Z * Z + C
            
            if MP.bStripes {
                stripet = (sin(Double(MP.stripes) * atan2(Z.imaginary, Z.real)) + 1) / 2
            }
            
            nZ = Z.lengthSquared
            if nZ > MP.bailout {
                if MP.bDist {
                    aZ = sqrt(nZ)
                    let logRatio = 2 * log(aZ) / log(MP.bailout)
                    smoothIter = 1 - log(logRatio) / log(2)
                    distance = aZ * log(aZ) / D.length / 2
                }
                
                if MP.bStripes {
                    stripeAvg = (stripeAvg * (1.0 + smoothIter * (MP.stripeSig-1)) + stripet * smoothIter * (1.0 - MP.stripeSig))
                    stripeAvg = stripeAvg / (1.0 - pow(MP.stripeSig, Double(i)) * (1.0 + smoothIter * (MP.stripeSig - 1.0)))
                }
                
                if MP.colorMapping.colorizeMode == .potential {
                    let logZn = log(nZ) / 2.0
                    potential = log(logZn / log2) / log2
                }
                
                return mapColorValue(Double(i)+smoothIter, nZ, Z/D, distance/MP.diag, potential, stripeAvg)
            }
            
            if MP.bOrbits {
                // Search for orbits (full periodicity check)
                var idx: Int = -1
                let e = max(-1, i - 100)
                
                for t in [1e-15, 1e-11] {
                    for n in stride(from: i-1, to: e, by: -1) {
                        let d = Z - orbits[n]
                        if d.real * d.real + d.imaginary * d.imaginary < t {
                            idx = n
                            continue
                        }
                    }
                }
                
                if idx > -1 {
                    // Found orbit, colorize point inside mandelbrot set
                    return RGBAColor(HSB(min(1.0, Float(Double(i-idx) / Double(MP.iterations) * MP.diaScale)), 1.0, 1.0 - Float(i)/Float(MP.iterations)))
                }
                orbits[i] = Z
            }
            else {
                // Simplified periodicity check, no orbit colorization
                if abs(nZ - nZ1) < 1e-10 {
                    orbitCount += 1
                    return MP.colorMapping.defColor
                }
                else {
                    period += 1
                    if period > 20 {
                        period = 0
                        nZ1 = nZ
                    }
                }
            }
            
            if MP.bStripes {
                stripeAvg = stripeAvg * MP.stripeSig + stripet * (1 - MP.stripeSig)
            }
        }
        
        return MP.colorMapping.defColor
    }
    
    // Calculate a line
    func calculateLine(_ graphics: ImageGraphics, _ y: Int, _ cplxLine: [Cplx]) {
        for i in 0..<cplxLine.count {
            let color = calculatePointZ2(cplxLine[i])
            graphics.setPixel(i, y, color)
        }
    }

    // Parallel calculation
    func calculatePar(_ graphics: ImageGraphics) {
        let cplxGrid = mapScreenCoordinates(graphics.width, graphics.height)

        // Calculate cpuCount lines in parallel
        DispatchQueue.concurrentPerform(iterations: cpuCount) { i in
            for y in stride(from: i, to: graphics.height, by: cpuCount) {
                calculateLine(graphics, y, cplxGrid[y])
            }
        }
    }
    
    // Sequential calculation
    func calculate(_ graphics: ImageGraphics) {
        let cplxGrid = mapScreenCoordinates(graphics.width, graphics.height)
        
        for y in 0..<graphics.height {
            for x in 0..<graphics.width {
                let color = calculatePointZ2(cplxGrid[y][x])
                graphics.setPixel(x, y, color)
            }
        }
    }
    
    func render(_ graphics: ImageGraphics) {
        let cplxGrid = mapScreenCoordinates(graphics.width, graphics.height)
        graphics.renderImage { imagePtr, index, x, y in
            let color = calculatePointZ2(cplxGrid[y][x])
            imagePtr[index] = color.redi
            imagePtr[index + 1] = color.greeni
            imagePtr[index + 2] = color.bluei
            imagePtr[index + 3] = color.alphai
        }
    }
    
    func calculate(_ graphics: CGGraphics) {
        let cplxGrid = mapScreenCoordinates(graphics.width, graphics.height)

        for y in 0..<graphics.height {
            graphics.moveTo(0, y)
            var curColor = calculatePointZ2(cplxGrid[y][0])
            for x in 1..<graphics.width {
                let newColor = calculatePointZ2(cplxGrid[y][x])
                if newColor != curColor || x == graphics.width - 1 {
                    graphics.drawHLineTo(x)
                    graphics.setColor(newColor)
                    curColor = newColor
                }
            }
        }
    }
    
}
