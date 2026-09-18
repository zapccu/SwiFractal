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
    typealias CT = RT.CT
    
    /// Default dimensions of Julia set
    static var defaultDimensions: FractalDimensions<Double> {
        FractalDimensions<Double>(cornerX: -1.5, cornerY: -1.5, sizeX: 3.0, sizeY: 3.0)
    }
    
    var fractalType: String { "Julia" }

    /// Parameter set with Julia set parameters
    var FP: ParSet<JuliaParameters<RT>>
    
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
        let settingsSnapshot = AppSettings.shared.snapshot()
        return DynamicParameters<DataType>(anypar: FP.current, resolution: resolution, settings: settingsSnapshot)
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
