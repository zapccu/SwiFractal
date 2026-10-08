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


///
/// Static Mandelbrot calculation parameters
///
nonisolated struct MandelbrotParameters<RT: PreciseFloatingPoint> : FractalData {
    
    /// Return default parameters
    static var defaultData: MandelbrotParameters<RT> {
        let defaultDimensions = FractalDimensions<RT>(cornerX: -2.25, cornerY: -1.5, sizeX: 3.0, sizeY: 3.0)
        return MandelbrotParameters<RT>(dimensions: defaultDimensions)
    }
    
    var initialMapping: InitialValueMapping<CT> {
        .init(kind: .mandelbrot, constant: CT.zero(precision: dimensions.precision.bits))
    }
    
    /// Name of fractal
    var name: String = "MandelbrotSet"

    /// Dimensions
    var dimensions: FractalDimensions<RT>

    /// Lightning parameters
    var lightParameters: LightningParameters = LightningParameters()
    
    /// Mandelbrot limits
    var limits: FractalLimits = FractalLimits()

    /// Coloring parameters
    var colorParameters: FractalColorParameters = FractalColorParameters()
    
    /// Return calculation methods supported by Mandelbrot fractal type
    var supportedCalculationMethods: [CalculationMethod] {
        [ .sequential, .sequentialPerturbation, .parallel, .metalcompute ]
    }
    
    /// Initialize Mandelbrot parameters
    /// - Parameter dimensions: Fractal dimensions
    init(dimensions: FractalDimensions<RT>) {
        self.dimensions = dimensions
    }
    
    /// Return initial values for Z and C
    @inline(__always) func initialValues(v: CT) -> (z0: CT, c: CT) {
        return (z0: CT.zero(precision: dimensions.precision.bits), c: v)
    }
    
    /// Convert dimensions of current MandelbrotParameters struct to Double
    /// - Returns: Copy of current MandelbrotParameters struct
    func toDouble() -> MandelbrotParameters<Double> {
        let newDimensions = dimensions.toDouble()
        var newMandelbrotParameters = MandelbrotParameters<Double>(dimensions: newDimensions)
        
        newMandelbrotParameters.lightParameters = lightParameters
        newMandelbrotParameters.limits          = limits
        newMandelbrotParameters.colorParameters = colorParameters
        
        return newMandelbrotParameters
    }
    
    /// Convert dimensions of current MandelbrotParameters struct to MPFloat
    /// - Parameter precision: Precision of dimension values
    /// - Returns: Copy of current MandelbrotParameters struct
    func toMPFloat(precision: Int) -> MandelbrotParameters<MPFloat> {
        let newDimensions = dimensions.toMPFloat(precision: precision)
        var newMandelbrotParameters = MandelbrotParameters<MPFloat>(dimensions: newDimensions)
        
        newMandelbrotParameters.lightParameters = lightParameters
        newMandelbrotParameters.limits          = limits
        newMandelbrotParameters.colorParameters = colorParameters
        
        return newMandelbrotParameters
    }
    
}


