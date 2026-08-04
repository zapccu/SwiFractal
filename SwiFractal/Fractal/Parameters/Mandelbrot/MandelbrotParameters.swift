//
//  MandelbrotParameters.swift
//  SwiFractal
//
//  Created by Dirk Braner on 13.02.26.
//

//
// Transfer structure for Metal compute parameters
//

import Foundation
import SwiftMPx


//
// Mandelbrot calculation limits
//
struct MandelbrotLimits: FractalParameters {
    var minIterationCount: Int = 200                // Minimum iteration count
    var iterations: Int = 200                       // Maximum number of iterations. default = 200
    var bailout: Double = 1e10                      // Bailout radius. default = 1e10
    var orbitDelta1: Double = 1e-15                 // Orbit detection: 1st delta = 1e-15
    var orbitDelta2: Double = 1e-11                 // Orbit detection: 2nd delta = 1e-11
    var orbitDelta3: Double = 1e-10                 // Orbit detection: delta for fast detection = 1e-10
    var orbitLength: Int = 20                       // Limit for fast orbit detection = 20
}

//
// Static Mandelbrot calculation parameters
//
nonisolated struct MandelbrotParameters<RT: PreciseFloatingPoint> : FractalData {
    
    typealias CT = RT.ComplexType
    
    /// Return default parameters
    static var defaultData: MandelbrotParameters<RT> {
        let defaultDimensions = FractalDimensions<RT>(cornerX: -2.25, cornerY: -1.5, sizeX: 3.0, sizeY: 3.0)
        return MandelbrotParameters<RT>(dimensions: defaultDimensions)
    }

    // Name of fractal
    var name: String = "MandelbrotSet"

    // Dimensions
    var dimensions: FractalDimensions<RT>
    
    var oversampling: Int = 1

    // Color table
    var colorTable: EnumColorTable = .smooth(smoothColorTable: ColorTableSmooth(
        "Grey-1024", colorPoints: [RGBAColor(80.0/255.0, 80.0/255.0, 80.0/255.0), .white], colorCount: 1024)
    )
    
    // Lightning parameters
    var lightning: LightningParameters = LightningParameters()
    
    // Mandelbrot limits
    var limits: MandelbrotLimits = MandelbrotLimits()

    // Coloring parameters
    var coloring: MandelbrotColoring = MandelbrotColoring()
    
    /// Initialize Mandelbrot parameters
    /// - Parameter dimensions: Fractal dimensions
    init(dimensions: FractalDimensions<RT>) {
        self.dimensions = dimensions
    }
    
    /// Convert dimensions of current MandelbrotParameters struct to Double
    /// - Returns: Copy of current MandelbrotParameters struct
    func toDouble() -> MandelbrotParameters<Double> {
        let newDimensions = dimensions.toDouble()
        var newMandelbrotParameters = MandelbrotParameters<Double>(dimensions: newDimensions)
        
        newMandelbrotParameters.oversampling = oversampling
        newMandelbrotParameters.colorTable   = colorTable
        newMandelbrotParameters.lightning    = lightning
        newMandelbrotParameters.limits       = limits
        newMandelbrotParameters.coloring     = coloring
        
        return newMandelbrotParameters
    }
    
    /// Convert dimensions of current MandelbrotParameters struct to MPFloat
    /// - Parameter precision: Precision of dimension values
    /// - Returns: Copy of current MandelbrotParameters struct
    func toMPFloat(precision: Int) -> MandelbrotParameters<MPFloat> {
        let newDimensions = dimensions.toMPFloat(precision: precision)
        var newMandelbrotParameters = MandelbrotParameters<MPFloat>(dimensions: newDimensions)
        
        newMandelbrotParameters.oversampling = oversampling
        newMandelbrotParameters.colorTable   = colorTable
        newMandelbrotParameters.lightning    = lightning
        newMandelbrotParameters.limits       = limits
        newMandelbrotParameters.coloring     = coloring
        
        return newMandelbrotParameters
    }
    
}


