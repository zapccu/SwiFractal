//
//  Mandelbrot.swift
//  SwiFractal
//
//  Created by Dirk Braner on 20.11.24.
//

import SwiftUI

// External packages
import Numerics
import Accelerate
import ParSetKit

//
// Mandelbrot fractal class
//
class Mandelbrot : Fractal<MandelbrotParameters> {
    
    // Dynamic parameters
    var DP: MandelbrotDynamicParameters? = nil
    
    // Statistic values
    var orbitCount: Int = 0
    
    // Minimum iteration count
    static var minIterationCount: Int = 200
    
    // Array of supported render functions
    override var calcFunctions: [DrawMethod: CalcFunc?]  {[
        .sequential: { [weak self] g in self?.calculateLineByLine(g) },
        .parallel:   { [weak self] g in self?.calculateParallel(g) },
        .metalcompute: { [weak self] g in self?.calculateMetal(g) },
        .metalshader:  nil
    ]}
    
    /// Return lower left corner of fractal as complex number
    var cplxCorner: Cplx { Cplx(FP.common.nCornerX, FP.common.nCornerY) }
    
    /// Return fractal resolution as complex number
    var cplxSize: Cplx { Cplx(FP.common.nSizeX, FP.common.nSizeY) }
    
    /// Return max iteration count depending on current zoom level (>= 500)
    var maxIterationCount: Int { Int(Double(Mandelbrot.minIterationCount) + log10(zoomFactor()) * 200) }
    
    /// Mark start of calculation. Prepare calculation parameters
    override func beginCalculation(_ width: Int, _ height: Int) {
        super.beginCalculation(width, height)
        DP = MandelbrotDynamicParameters(parameters: FP.current, imageWidth: width, imageHeight: height)
        orbitCount = 0
    }
    
    /// Mark end of calculationsize
    override func endCalculation() {
        super.endCalculation()
        debugPrint("orbitCount: \(orbitCount)")
    }
    
    /// Calculate pixel distance
    func pixelDistance(_ imageWidth: Int, _ imageHeight: Int) -> Cplx {
        let size: Cplx = cplxSize
        return Cplx(size.real / Double(imageWidth - 1), size.imaginary / Double(imageHeight - 1))
    }
    
    /// Map screen coordinates to fractal point
    func mapXY(_ point: CGPoint, _ imageWidth: Int, _ imageHeight: Int) -> Cplx {
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
        let currentSize: Cplx = cplxSize
        return CommonParameters.defaultSize / currentSize.min
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
    override func zoomArea(_ area: CGRect, _ imageWidth: Int, _ imageHeight: Int) -> (Cplx, Cplx) {
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


        
}
