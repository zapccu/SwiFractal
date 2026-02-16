//
//  Mandelbrot.swift
//  SwiFractal
//
//  Created by Dirk Braner on 20.11.24.
//

import SwiftUI
import Numerics
import Accelerate



class Mandelbrot: Fractal {
       
    // Mandelbrot set calculation parameters
    var MP: MandelbrotParameters = MandelbrotParameters()
    
    // 2 dimensional array with complex coordinates
    var cplxGrid: [[Cplx]] = []
    
    // 2 dimensional array with number of iterations per pixel (index = y, x)
    var iterationCountPerPixel: [[Int]] = []
    
    // Array with number of pixels with iteration count (index = iteration count)
    var pixelCountPerIteration: [Int] = []
    
    // Count orbits found during calculation
    var orbitCount: Int = 0
    
    /// Initialize Mandelbrot object
    ///
    /// childClassName: Name of child class, used as sub-path-element
    /// childClassDct: Dictionary with fractal settings of child class
    ///
    override init(_ childClassName: String = "", _ childClassDict: DictAny = [:]) {
        // Add default settings for Mandelbrot set in sub-element [classname] of parent class
        let className = String(describing: type(of: self))
        super.init(className, [
            "iterations": 500,
            "stripes": 0,           // Stripe density 0..32
            "steps": 0,             // Step density 0..100
            "ncycle": 1.0,          // Color cycling 1..200
            "colorTable": "Grey",
            "paletteMode": PaletteMode(.linear),
            "colorizeMode": ColorizeMode(.iterations),
            "colorizeOutside": ColorizeOutside(.simple),
            "colorizeInside": ColorizeInside(.simple)
        ])
        
        // Add settings of child classes
        // childClassName and dict are empty by default (no child classes)
        if !childClassName.isEmpty && !childClassDict.isEmpty {
            let childClassPath = className + "." + childClassName
            _ = settings.addSetting(childClassPath, childClassDict)
        }
        
        // Create default calculation parameters
        MP = MandelbrotParameters(settings)
    }
    
    /// Mark start of calculation. Prepare calculation parameters
    func beginCalculation(_ width: Int, _ height: Int) {
        MP = MandelbrotParameters(settings)
        //dump(MP)
        mapScreenCoordinates(width, height)
        orbitCount = 0
        super.beginCalculation()
    }
    
    /// Mark end of calculation
    override func endCalculation() {
        super.endCalculation()
        print("orbitCount: \(orbitCount)")
    }
    
    /// Adjust complex area to consider aspect ratio of drawing area
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
    
    /// Calculate pixel distance
    func pixelDistance(_ imageWidth: Int, _ imageHeight: Int) -> Cplx {
        let size: Cplx = settings["size"]
        return Cplx(size.real / Double(imageWidth - 1), size.imaginary / Double(imageHeight - 1))
    }
    
    /// Map screen coordinates to fractal point
    func mapXY(_ point: CGPoint, _ imageWidth: Int, _ imageHeight: Int) -> Cplx {
        let corner: Cplx = settings["corner"]
        let dXY = pixelDistance(imageWidth, imageHeight)
        return corner + Cplx(point.x * dXY.real, point.y * dXY.imaginary)
    }

    /// Map screen dimensions to fractal size
    func mapWH(_ size: CGSize, _ imageWidth: Int, _ imageHeight: Int) -> Cplx {
        let dXY = pixelDistance(imageWidth, imageHeight)
        return Cplx(dXY.real * size.width, dXY.imaginary * size.height)
    }
    
    /// Zoom into screen area
    func zoomArea(_ area: CGRect, _ imageWidth: Int, _ imageHeight: Int) -> (Cplx, Cplx) {
        print("Zoom area: \(area.origin), \(area.width), \(area.height)")

        if Int(area.width) == imageWidth && Int(area.height) == imageHeight {
            return (settings["corner"], settings["size"])
        }
        
        let size   = mapWH(area.size, imageWidth, imageHeight)
        let corner = mapXY(area.origin, imageWidth, imageHeight)
        
        print("New corner = \(corner), new size = \(size)")
        
        return (corner, size)
    }

    /// Create matrix of complex values representing the pixels of the drawing area
    func mapScreenCoordinates(_ imageWidth: Int, _ imageHeight: Int, corner: Cplx? = nil, size: Cplx? = nil, aspectRatio: Bool = true) {
        var c = corner ?? settings["corner"]
        var s = size   ?? settings["size"]
        
        if aspectRatio {
            (c, s) = adjustAspectRatio(imageWidth, imageHeight, c, s)
        }

        cplxGrid = linspace(c, c + s, imageWidth, imageHeight)
        
        if MP.colorMapping.paletteMode == .histogram {
            iterationCountPerPixel = Array(repeating: Array<Int>(repeating: 0, count: imageHeight), count: imageWidth)
            pixelCountPerIteration = Array<Int>(repeating: 0, count: (settings["iterations"] as Int))
        }
    }
    
    /// Map iteration result to color. Return RGBAColor value.
    ///
    /// - Parameters
    /// * iterations: Number of iterations including smooth iterations value
    ///
    /// *nZ: norm(Z)
    ///x
    /// **normal**: Z/D
    ///
    /// **distance**: Distance to Mandelbrot set
    ///
    /// **potential**: Potential
    ///
    /// **stripeAvg**: Average stripe value
    ///
    func mapColorValue(_ iterations: Double, _ nZ: Double, _ normal: Cplx, _ distance: Double, _ potential: Double, _ stripeAvg: Double) -> RGBAColor {
        // Reduce palette lenght by 1 for indexing
        let pLen = Double(MP.colorMapping.colorCount) - 1
        
        // The brightness 0..1
        var brightness: Double = 1.0
        
        // The resulting color
        var color = MP.colorMapping.defColor
        
        // Color cycling
        // cycle_iter in range 0..1 (floating point modulo!)
        let cycleIter = (sqrt(iterations) % MP.ncycle) / MP.ncycle
        
        let di = iterations / Double(MP.iterations)
        
        // 3D shading, calculate brightness
        if MP.colorMapping.colorizeOutside.isAny(of: [.blinnPhong, .simple3d]) {
            let absNormal = normal / normal.length
            let vecNormal = Vector(absNormal.real, absNormal.imaginary, 1.0)
            
            // Simple 3D shading
            if MP.colorMapping.colorizeOutside == .simple3d {
                brightness = MP.lightning.simple3D(vecNormal)
            }
            
            // Blinn Phong 3D shading
            else if MP.colorMapping.colorizeOutside == .blinnPhong {
                brightness = MP.lightning.blinnPhong(vecNormal)
            }
        }

        let fBrightness = Float(brightness)

        // Color based on stripes or steps. colorize and palette mode do not matter here
        if MP.colorMapping.colorizeMode.isAny(of: [.steps, .stripes]) {
            color = shading(iterations, distance, stripeAvg, brightness)
        }
        
        // Color based on iterations
        else if MP.colorMapping.colorizeMode == .iterations {
            
            // Linear mapping
            if MP.colorMapping.paletteMode == .linear {
                color = MP.colorMapping[Int(di * pLen)] * fBrightness
            }
            
            // Modulo division mapping
            else if MP.colorMapping.paletteMode == .modulo {
                color = MP.colorMapping[Int(di * pLen) % Int(MP.ncycle)] * fBrightness
            }
            
            // Color cycling mapping
            else if MP.colorMapping.paletteMode == .cycling {
                color = MP.colorMapping[Int(round(cycleIter * pLen))] * fBrightness
            }
            /*
            else if MP.colorMapping.paletteMode == .hue {
                color = hsb2rgb(P[0,0], P[0,1], bright)
            }
             */
            
            // Hue dynamic mapping
            else if MP.colorMapping.paletteMode == .huedyn {
                let h = Double(Int(pow((iterations) * 360, 1.5)) % 360)
                // For hsl model saturation must be set to 0.5
                color = RGBAColor(HSB(Float(h/360), 1.0, fBrightness))
            }
            
            // Lch dynamic mapping
            else if MP.colorMapping.paletteMode == .lchdyn {
                let cpidi = cos(Double.pi * di)
                let v = 1.0 - cpidi * cpidi
                let lch = LCH(Float(75.0 - (75.0 * v)), Float(28.0 + (75.0 - (75.0 * v))), Float(pow(360.0 * di, 1.5) % 360.0))
                color = RGBAColor(lch) * fBrightness
            }
        }
        
        // Color based on distance
        else if MP.colorMapping.colorizeMode == .distance {
            color = MP.colorMapping[Int(tanh(distance) * pLen)] * fBrightness
        }
        
        // Color based on potential
        else if MP.colorMapping.colorizeMode == .potential {
            let lognZ12 = log(nZ) / 2.0
            let nu = log(lognZ12 / _NC.LOG2) / _NC.LOG2
            let i = iterations + 1.0 - nu
            let color1 = MP.colorMapping[Int(i)]
            let color2 = MP.colorMapping[Int(i) + 1]
            let ic: Double = i % 1.0
            let cv = vDSP.linearInterpolate(color1.vector3, color2.vector3, using: ic)
            color = RGBAColor(cv) * fBrightness
        }
        /*
         exponentially / cyclic color mapping
         
         Int(pow(pow(iterations / Double(MP.iterations), 2.0) * Double(MP.colorMapping.colorCount), 1.5)) % MP.colorMapping.colorCount
         */

        // Return color with gamma correction
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
        
    func calculatePointZ2(_ x: Int, _ y: Int) -> RGBAColor {
        var color = MP.colorMapping.defColor
        
        let C = cplxGrid[y][x]
        
        var distance: Double = 0.0
        var potential: Double = 0.0
        var stripeAvg: Double = 0.0
        var stripet: Double = 0.0
        
        var Z = Cplx(0.0)
        var nZ: Double = 0.0        // Norm of Z: Z.imaginary * Z.imageinary + Z.real * Z.real
        var nZ1: Double = 10.0      // Old value of nZ for fast orbit detection
        var aZ: Double = 0.0        // abs(Z) = sqrt(nZ)
        var period: Int = 0         // Period counter for fast orbit detection
        var D = Cplx(0.0, 0.0)      // 1st derivation of Z
        var smoothIter: Double = 0  // Smooth iteration counter
        var potf: Double = 0.5      // Potential factor 1/2^N
        
        var orbits = Array<Cplx>(repeating: Cplx(0.0), count: MP.iterations+1)
        
        for i in 0...MP.iterations {
            
            Z = Z * Z + C
            
            if MP.stripes > 0 {
                stripet = (sin(Double(MP.stripes) * atan2(Z.imaginary, Z.real)) + 1.0) * 0.5
            }
            
            nZ = Z.lengthSquared
            
            if nZ > MP.bailout {
                aZ = sqrt(nZ)           // aZ = abs(Z)
                let logaZ = log(aZ)
                
                // logRatio = 2 * log(aZ) / log(bailout)
                // Using precalculated values
                // log2Bailout = 2 / log(bailout)
                let logRatio = logaZ * MP.log2Bailout
                
                // Calculate smooth iteration value
                // 1.0 - log(logRatio) / log(2)
                smoothIter = 1.0 - log(logRatio) * _NC.RLOG2
                
                // Calculate exterior distance to Mandelbrot set
                // aZ * log(aZ) / abs(D) / 2.0
                distance = aZ * logaZ / D.length / 2.0
                
                // Calculate potential
                // pot = log(abs(Z)) / 2^N
                // potf already contains 1/2^N
                //
                // Alternative calculation:
                // let lognZ = log(nZ) * 0.5
                // potential = log(lognZ / _NC.LOG2) / _NC.LOG2
                potential = logaZ * potf
                
                // Calculate stripes
                if MP.stripes > 0 {
                    stripeAvg = (stripeAvg * (1.0 + smoothIter * (MP.stripeSig - 1.0)) + stripet * smoothIter * (1.0 - MP.stripeSig))
                    stripeAvg = stripeAvg / (1.0 - pow(MP.stripeSig, Double(i)) * (1.0 + smoothIter * (MP.stripeSig - 1.0)))
                }
                
                // Count iterations for calculation of histogram
                if MP.bHist && i < MP.iterations {
                    iterationCountPerPixel[y][x] = i
                    pixelCountPerIteration[i] += 1
                }
                
                return MP.colorMapping.mapColorValue(Double(i)+smoothIter, MP.iterations, nZ, Z/D, distance * MP.diag, potential, stripeAvg)

                // return mapColorValue(Double(i)+smoothIter, nZ, Z/D, distance * MP.diag, potential, stripeAvg)
            }
            
            // Calculate orbits
            if MP.bOrbits {
                // Search for orbits (full periodicity check)
                var idx: Int = -1
                let end: Int = max(-1, i - 100)
                
                for t in [MP.orbitDelta1, MP.orbitDelta2] {
                    for n in stride(from: i-1, to: end, by: -1) {
                        let d = Z - orbits[n]
                        if d.lengthSquared < t {
                            idx = n
                            break
                        }
                    }
                }
                
                if idx > -1 {
                    // Found orbit, colorize point inside mandelbrot set
                    color = RGBAColor(HSB(min(1.0, Float(Double(i-idx) / Double(MP.iterations) * MP.diaScale)), 1.0, 1.0 - Float(i)/Float(MP.iterations)))
                    break
                }
                orbits[i] = Z
            }
            else {
                // Simplified periodicity check, no orbit colorization
                if abs(nZ - nZ1) < MP.orbitDelta3 {
                    orbitCount += 1
                    break
                }
                else {
                    period += 1
                    if period > MP.orbitLength {
                        period = 0
                        nZ1 = nZ
                    }
                }
            }
            
            if MP.stripes > 0 {
                stripeAvg = stripeAvg * MP.stripeSig + stripet * (1 - MP.stripeSig)
            }
            
            // Derivation D of Z
            // D = D * 2.0 * Z + 1.0
            D = (Z + Z) * D + 1.0
            
            potf *= 0.5
        }
        
        if MP.bHist { iterationCountPerPixel[y][x] = MP.iterations }
        
        return color
    }

    /// Calculate a line without modifying graphics color and drawing position
    func calculateLine(_ graphics: Graphics, _ y: Int) {
        var color = calculatePointZ2(0, y)
        var pt = CGPoint(x: 0, y: y)
        
        for x in 1..<graphics.width {
            let newColor = calculatePointZ2(x, y)
            if newColor != color {
                pt = graphics.drawHLine(pt, x, color: color)
                color = newColor
            }
        }
        
        _ = graphics.drawHLine(pt, graphics.width, color: color)
    }
    
    /// Parallel calculation of Mandelbrot set
    func calculateParallel(_ graphics: Graphics) {
        // Calculate cpuCount lines in parallel
        DispatchQueue.concurrentPerform(iterations: cpuCount) { i in
            for y in stride(from: i, to: graphics.height, by: cpuCount) {
                calculateLine(graphics, y)
            }
        }
    }
    
    /// Metal / GPU calculation of Mandelbrot set
    func calculateMetal(_ graphics: Graphics) {
        // Convert complex grid to 1 dimensional array
        let C = cplxGrid.joined().map { Complex2($0) }
        
        do {
            let metalCompute = try MetalCompute("mandelbrot")

            try metalCompute.addBuffer(C, .computeInputBuffer)
            try metalCompute.addBuffer(MP.colorMapping.palette.rgbaColors, .inputBuffer)
            metalCompute.addObject(MP.computeParameters)
            
            // Compute Mandelbrot set
            let result = try metalCompute.compute(RGBAColor.black.rgba)
            graphics.initFromColorArray(result)
        }
        catch {
            print(error)
        }
    }
    

    /// Sequential calculation of Mandelbrot set line by line
    func calculateLineByLine(_ graphics: Graphics) {
        for y in 0..<graphics.height {
            calculateLine(graphics, y)
        }
        
        if MP.bHist {
            let total = Double(pixelCountPerIteration.reduce(0, +))
            for y in 0..<graphics.height {
                for x in 0..<graphics.width {
                    let iter = iterationCountPerPixel[y][x]
                    if iter == MP.iterations { continue }
                    var hue = 0.0
                    for i in 0...iter {
                        hue += Double(pixelCountPerIteration[i]) / total
                        let ci = Int(Double(MP.colorMapping.colorCount) * hue)
                        graphics.setPixel(x, y, color: MP.colorMapping[ci])
                    }
                }
            }
        }
    }
    
}
