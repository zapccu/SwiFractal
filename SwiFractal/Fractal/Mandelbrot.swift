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
    
    // Minimum iteration count
    static var minIterationCount: Int = 200
       
    // Mandelbrot set calculation parameters
    var MP: MandelbrotParameters = MandelbrotParameters()
    
    override var calcFunctions: [CalcFunc?] { Array([
        calculateLineByLine,
        calculateParallel,
        calculateMetal,
        nil
    ]) }
    
    var cplxCorner: Cplx {
        Cplx(Double(settings["cornerLeft", default: "-2.25"]) ?? -2.25, Double(settings["cornerBottom", default: "-1.5"]) ?? -1.5)
    }
    
    var cplxSize: Cplx {
        Cplx(Double(settings["sizeX", default: "3.0"]) ?? 3.0, Double(settings["sizeY", default: "3.0"]) ?? 3.0)
    }
    
    /// Return max iteration count depending on current zoom level (>= 500)
    var maxIterationCount: Int { Int(Double(Mandelbrot.minIterationCount) + log10(zoomFactor()) * 200) }
    
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
    override func beginCalculation(_ width: Int, _ height: Int) {
        dump(settings)
        MP = MandelbrotParameters(settings)
        mapScreenCoordinates(width, height)
        orbitCount = 0
        super.beginCalculation(width, height)
    }
    
    /// Mark end of calculationsize
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
        // let size: Cplx = settings["size"]
        let size: Cplx = cplxSize
        return Cplx(size.real / Double(imageWidth - 1), size.imaginary / Double(imageHeight - 1))
    }
    
    /// Map screen coordinates to fractal point
    func mapXY(_ point: CGPoint, _ imageWidth: Int, _ imageHeight: Int) -> Cplx {
        // let corner: Cplx = settings["corner"]
        let dXY = pixelDistance(imageWidth, imageHeight)
        return cplxCorner + Cplx(point.x * dXY.real, point.y * dXY.imaginary)
    }

    /// Map screen dimensions to fractal size
    func mapWH(_ size: CGSize, _ imageWidth: Int, _ imageHeight: Int) -> Cplx {
        let dXY = pixelDistance(imageWidth, imageHeight)
        return Cplx(dXY.real * size.width, dXY.imaginary * size.height)
    }
    
    /// Return zoom factor
    func zoomFactor() -> Double {
        let sizeX: Double = Double(settings.initial[path: "sizeX", default: "3.0"]) ?? 3.0
        let sizeY: Double = Double(settings.initial[path: "sizeY", default: "3.0"]) ?? 3.0
        let currentSize: Cplx = cplxSize
        
        return max(sizeX, sizeY) / currentSize.min
    }
    
    /// Check if Double precision is sufficient for current pixel size
    ///
    /// Returns true, if precision is sufficient
    ///
    func checkPrecision(_ center: Cplx, _ resolution: Int, _ securityFactor: Double = 100.0) -> Bool {
        // let currentSize: Cplx = settings.current[path: "size"]
        let currentSize: Cplx = cplxSize
        let pixelSize = currentSize.min / Double(resolution)
        
        // Security factor = 100
        return pixelSize >= (center.ulp * securityFactor)
    }
    
    /// Zoom into screen area
    func zoomArea(_ area: CGRect, _ imageWidth: Int, _ imageHeight: Int) -> (Cplx, Cplx) {
        print("Zoom area: \(area.origin), \(area.width), \(area.height)")

        if Int(area.width) == imageWidth && Int(area.height) == imageHeight {
            // return (settings["corner"], settings["size"])
            return (cplxCorner, cplxSize)
        }
        
        let sizeNew   = mapWH(area.size, imageWidth, imageHeight)
        let cornerNew = mapXY(area.origin, imageWidth, imageHeight)
        
        print("New corner = \(cornerNew), new size = \(sizeNew)")
        
        return (cornerNew, sizeNew)
    }

    /// Create matrix of complex values representing the pixels of the drawing area
    func mapScreenCoordinates(_ imageWidth: Int, _ imageHeight: Int, corner: Cplx? = nil, size: Cplx? = nil, aspectRatio: Bool = true) {
        // var c = corner ?? settings["corner"]
        // var s = size   ?? settings["size"]
        var c = corner ?? cplxCorner
        var s = size   ?? cplxSize
        
        if aspectRatio {
            (c, s) = adjustAspectRatio(imageWidth, imageHeight, c, s)
        }

        cplxGrid = linspace(c, c + s, imageWidth, imageHeight)
        
        if MP.colorMapping.paletteMode == .histogram {
            iterationCountPerPixel = Array(repeating: Array<Int>(repeating: 0, count: imageHeight), count: imageWidth)
            pixelCountPerIteration = Array<Int>(repeating: 0, count: (settings["iterations"] as Int))
        }
    }
        
}
