//
//  Mandelbrot.swift
//  SwiFractal
//
//  Created by Dirk Braner on 20.11.24.
//

import SwiftUI

// External packages
import Numerics
import SwiftMPx
import ParSetKit
import Accelerate

///
/// Mandelbrot fractal class
///
@Observable
@MainActor
final class Mandelbrot<RT: PreciseFloatingPoint> : FractalProtocol {
    
    typealias DataType = MandelbrotParameters<RT>
    typealias ResultType = MandelbrotResult
    typealias CT = RT.CT
    
    /// Return default dimensions of Mandelbrot set
    static var defaultDimensions: FractalDimensions<Double> {
        FractalDimensions<Double>(cornerX: -2.25, cornerY: -1.5, sizeX: 3.0, sizeY: 3.0)
    }
    
    /// Return fractal type as String
    var fractalType: String { "Mandelbrot" }

    /// Parameter set with MandelbrotParameters
    var FP: ParSet<MandelbrotParameters<RT>>
    
    /// Initialize Mandelbrot set
    /// - Parameter mandelbrotParameters: Mandelbrot parameters
    init(mandelbrotParameters: MandelbrotParameters<RT> = MandelbrotParameters.defaultData) {
        // Never set autoVersioning to true! This doesn't work with SwiftUI
        self.FP = ParSet(initial: mandelbrotParameters, autoVersioning: false)
    }

}
