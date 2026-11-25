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

}
