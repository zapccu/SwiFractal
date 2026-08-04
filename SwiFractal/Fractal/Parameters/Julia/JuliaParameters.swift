//
//  JuliaParameters.swift
//  SwiFractal
//
//  Created by Dirk Braner on 27.07.26.
//

import Foundation
import SwiftMPx


//
// Static Julia calculation parameters
//
nonisolated struct JuliaParameters<RT: PreciseFloatingPoint> : IterationData {
    
    /// Return default parameters
    static var defaultData: JuliaParameters<RT> {
        let defaultDimensions = FractalDimensions<RT>(cornerX: -1.5, cornerY: -1.5, sizeX: 3.0, sizeY: 3.0)
        return JuliaParameters<RT>(dimensions: defaultDimensions)
    }
    
    /// Name of fractal
    var name: String = "JuliaSet"
    
    /// Fractal dimensions
    var dimensions: FractalDimensions<RT>
    
    // Lightning parameters
    var lightParameters: LightningParameters = LightningParameters()
    
    // Mandelbrot limits
    var limits: FractalLimits = FractalLimits()

    // Coloring parameters
    var coloring: FractalColoring = FractalColoring()
    
    /// Real value of complex point of Julia set
    var cPointX: RT
    
    /// Imaginary value of complex point of Julia set
    var cPointY: RT
    
    /// Get or set cPointX as String
    var strCPointX: String {
        get { cPointX.toString()}
        set { cPointX = RT(newValue, precision: dimensions.precision.bits ) }
    }
    
    /// Get or set cPointY as String
    var strCPointY: String {
        get { cPointY.toString()}
        set { cPointY = RT(newValue, precision: dimensions.precision.bits ) }
    }
    
    /// Return supported calculation methods
    var supportedCalculationMethods: [CalculationMethod] {
        [.sequential, .parallel, .metalcompute ]
    }
    
    /// Initialize Julia set parameters
    /// - Parameter dimensions: Fractal dimensions
    init(dimensions: FractalDimensions<RT>) {
        self.dimensions = dimensions
        self.cPointX    = .zero
        self.cPointY    = .zero
        self.name       = "JuliaSet"
    }
    
    /// Return initial values for Z and C
    @inlinable func initialValues(v: CT) -> (z0: CT, c: CT) {
        return (z0: v, c: CT(cPointX, cPointY))
    }
    
    /// Convert dimensions of current JuliaParameters struct to Double
    /// - Returns: Copy of current JuliaParameters struct
    func toDouble() -> JuliaParameters<Double> {
        let newDimensions = dimensions.toDouble()
        var newJuliaParameters = JuliaParameters<Double>(dimensions: newDimensions)
        
        newJuliaParameters.lightParameters = lightParameters
        newJuliaParameters.limits          = limits
        newJuliaParameters.coloring        = coloring
        newJuliaParameters.cPointX         = cPointX.asDouble
        newJuliaParameters.cPointY         = cPointY.asDouble
        
        return newJuliaParameters
    }
    
    /// Convert dimensions of current JuliaParameters struct to MPFloat
    /// - Parameter precision: Precision of dimension values
    /// - Returns: Copy of current JuliaParameters struct
    func toMPFloat(precision: Int) -> JuliaParameters<MPFloat> {
        let newDimensions = dimensions.toMPFloat(precision: precision)
        var newJuliaParameters = JuliaParameters<MPFloat>(dimensions: newDimensions)
        
        newJuliaParameters.lightParameters = lightParameters
        newJuliaParameters.limits          = limits
        newJuliaParameters.coloring        = coloring
        newJuliaParameters.cPointX         = cPointX.toMPFloat(precision: precision)
        newJuliaParameters.cPointY         = cPointY.toMPFloat(precision: precision)

        return newJuliaParameters
    }
    
}

