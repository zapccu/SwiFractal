//
//  Julia.swift
//  SwiFractal
//
//  Created by Dirk Braner on 27.07.26.
//

import SwiftUI

// External packages
import Numerics
import SwiftMPx
import ParSetKit
import Accelerate

//
// Mandelbrot fractal class
//
@Observable
@MainActor
class Julia<RT: PreciseFloatingPoint> : FractalProtocol {

    typealias DataType = JuliaParameters<RT>
    typealias ResultType = MandelbrotResult
    typealias CT = RT.ComplexType
    
    /// Dictionary with calculation methods and functions supported by Julia
    nonisolated static var calculationFunctions: [CalculationMethod: CalculationFunction] {
        [
            .sequential:    FractalCalculation<DataType>.calculateLineByLine,
            .parallel:      FractalCalculation<DataType>.calculateParallel,
            .metalcompute:  FractalCalculation<DataType>.calculateMetal,
        ]
    }
    
    /// Default dimensions of Julia set
    static var defaultDimensions: FractalDimensions<Double> {
        FractalDimensions<Double>(cornerX: -1.5, cornerY: -1.5, sizeX: 3.0, sizeY: 3.0)
    }

    /// Parameter set with Julia set parameters
    var FP: ParSet<JuliaParameters<RT>>
    
    /// Current image
    //var image: CGImage?
    
    /// Zoomed image
    //var zoomedImage: CGImage?
    
    /// Initialize Mandelbrot set
    /// - Parameter mandelbrotParameters: Mandelbrot parameters
    init(juliaParameters: JuliaParameters<RT> = JuliaParameters.defaultData) {
        // Never set autoVersioning to true! This doesn't work with SwiftUI
        self.FP = ParSet(initial: juliaParameters, autoVersioning: false)
    }
        
    /// Mark start of calculation. Prepare calculation parameters
    /// - Parameters:
    ///   - size: Output graphics size
    /// - Returns: true if calculation parameters prepared successfully
    func beginCalculation(resolution: CGSize) -> DynamicParameters<DataType>? {
        return DynamicParameters(anypar: FP.current, resolution: resolution)
        //return DynamicParameters<RT>(parameters: FP.current.mandelbrotParameters, resolution: resolution)
    }
    
    /// Mark end of calculation
    /// - Parameter state: Calculation state
    func endCalculation(_ state: CalculationState) {
    }
    
    /// Zoom into fractal
    /// - Parameters:
    ///   - area: Area to zoom into
    ///   - resolution: Image resolution
    /// - Returns: New fractal object considering a change of fractal dimensions precision
    func zoom(into area: CGRect, resolution: CGSize) -> any FractalProtocol {
        let newDimensions = FP.dimensions.zoomArea(area: area, resolution: resolution)
        switch newDimensions {
        case .double(let dim):
            let parameters = MandelbrotParameters<Double>(dimensions: dim)
            return Mandelbrot<Double>(mandelbrotParameters: parameters)
        case .mpfloat(let dim):
            let parameters = MandelbrotParameters<MPFloat>(dimensions: dim)
            return Mandelbrot<MPFloat>(mandelbrotParameters: parameters)
        }
    }

}
