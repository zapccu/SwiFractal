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
class Mandelbrot<RT: PreciseFloatingPoint> : FractalProtocol {
    
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
        
    /// Mark start of calculation. Prepare calculation parameters
    /// - Parameters:
    ///   - size: Output graphics size without oversampling
    /// - Returns: Dynamic calculation parameter structure
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

    /// Iterate an array of complex points
    /// - Parameters:
    ///   - P: Dynamic calculation parameters
    ///   - inRow: Array of complex points
    ///   - outRow: Array of calculation results
    /*
    nonisolated static func calculateLine(P: DynamicParameters<DataType>,
                                          inRow: UnsafeBufferPointer<CT>,
                                          outRow: UnsafeMutableBufferPointer<ResultType>) {
        for i in inRow.indices {
            outRow[i] = calculatePointZ2(CP: inRow[i], P: P)
        }
    }
     

    nonisolated static func calculateLineFast(P: DynamicParameters<DataType>,
                                              inRow: UnsafeBufferPointer<CT>,
                                              outRow: UnsafeMutableBufferPointer<ResultType>) {
        for i in stride(from: inRow.startIndex, to: inRow.endIndex, by: 2) {
            outRow[i] = calculatePointZ2(CP: inRow[i], P: P)
            outRow[i + 1] = outRow[i]
        }
    }
     */
}
