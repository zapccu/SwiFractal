//
//  JuliaParameters.swift
//  SwiFractal
//
//  Created by Dirk Braner on 27.07.26.
//

import Foundation
import SwiftMPx


//
// Static Mandelbrot calculation parameters
//
nonisolated struct JuliaParameters<RT: PreciseFloatingPoint> : FractalData {
    
    typealias CT = RT.ComplexType
    
    /// Return default parameters
    static var defaultData: JuliaParameters<RT> {
        let defaultDimensions = FractalDimensions<RT>(cornerX: -1.5, cornerY: -1.5, sizeX: 3.0, sizeY: 3.0)
        return JuliaParameters<RT>(dimensions: defaultDimensions)
    }

    // Name of fractal
    var name: String = "MandelbrotSet"

    // Dimensions
    var dimensions: FractalDimensions<RT>
    
    // Complex point of Julia set
    var cplxPointX: RT
    var cplxPointY: RT
    
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
        self.cplxPointX = .zero
        self.cplxPointY = .zero
    }
    
    /// Convert dimensions of current JuliaParameters struct to Double
    /// - Returns: Copy of current JuliaParameters struct
    func toDouble() -> JuliaParameters<Double> {
        let newDimensions = dimensions.toDouble()
        var newJuliaParameters = JuliaParameters<Double>(dimensions: newDimensions)
        
        newJuliaParameters.cplxPointX   = cplxPointX.toDouble()
        newJuliaParameters.cplxPointY   = cplxPointY.toDouble()
        newJuliaParameters.oversampling = oversampling
        newJuliaParameters.colorTable   = colorTable
        newJuliaParameters.lightning    = lightning
        newJuliaParameters.limits       = limits
        newJuliaParameters.coloring     = coloring
        
        return newJuliaParameters
    }
    
    /// Convert dimensions of current JuliaParameters struct to MPFloat
    /// - Parameter precision: Precision of dimension values
    /// - Returns: Copy of current JuliaParameters struct
    func toMPFloat(precision: Int) -> JuliaParameters<MPFloat> {
        let newDimensions = dimensions.toMPFloat(precision: precision)
        var newJuliaParameters = JuliaParameters<MPFloat>(dimensions: newDimensions)
        
        newJuliaParameters.cplxPointX    = cplxPointX.toMPFloat(precision: precision)
        newJuliaParameters.cplxPointY    = cplxPointY.toMPFloat(precision: precision)
        newJuliaParameters.oversampling = oversampling
        newJuliaParameters.colorTable   = colorTable
        newJuliaParameters.lightning    = lightning
        newJuliaParameters.limits       = limits
        newJuliaParameters.coloring     = coloring
        
        return newJuliaParameters
    }
    
}

