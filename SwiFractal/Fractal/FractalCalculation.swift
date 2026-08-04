//
//  FractalCalculation.swift
//  SwiFractal
//
//  Created by Dirk Braner on 31.07.26.
//

import Foundation
import SwiftUI
import SwiftMPx


struct SendableRow<T>: @unchecked Sendable {
    let buffer: UnsafeBufferPointer<T>
}

struct SendableMutableRow<T>: @unchecked Sendable {
    let buffer: UnsafeMutableBufferPointer<T>
}

enum FractalCalculation<PT: IterationData> {
    
    typealias RT = PT.RT
    typealias CT = RT.ComplexType
    
    typealias CalculationFunction = @Sendable (DynamicParameters<PT>) async -> Matrix<MandelbrotResult>
    
    /// Dictionary with calculation functions for calculation methods
    nonisolated static var calculationFunctions: [CalculationMethod: CalculationFunction] {
        [
            .sequential:    calculateLineByLine,
            .parallel:      calculateParallel,
            .metalcompute:  calculateMetal,
            .metalshader:   calculateMetal
        ]
    }
    
    static func getFunction(method: CalculationMethod, P: PT) -> CalculationFunction? {
        if P.supportedCalculationMethods.contains(method) {
            return calculationFunctions[method]
        }
        return nil
    }
    
    /// Iterate an array of complex points
    /// - Parameters:
    ///   - P: Dynamic calculation parameters
    ///   - inRow: Array of complex points
    ///   - outRow: Array of calculation results
    nonisolated static func calculateLine(
        P: DynamicParameters<PT>,
        inRow: UnsafeBufferPointer<CT>,
        outRow: UnsafeMutableBufferPointer<MandelbrotResult>
    ) {
        for i in inRow.indices {
            let (z0, c) = P.fractalParameters.initialValues(v: inRow[i])
            outRow[i] = calculatePointZ2(Z0: z0, C: c, P: P)
        }
    }
    
    /// Sequential calculation of Mandelbrot set line by line
    /// - Parameters:
    ///   - P: Calculation parameters
    /// - Returns: Matrix of calculation results in dimensions (height, width)
    nonisolated static func calculateLineByLine(P: DynamicParameters<PT>) async -> Matrix<MandelbrotResult> {
        // Create the output matrix
        var result = Matrix<MandelbrotResult>((P.osImageHeight, P.osImageWidth), defaultValue: .defaultValue)
        
        // Create the input matrix
        let cplxGrid: Matrix<PT.RT.ComplexType> = P.dimensions.mapScreenCoordinates(resolution: P.resolution, osSize: P.osSize)
        
        cplxGrid.grid.withUnsafeBufferPointer { inBuffer in
            result.grid.withUnsafeMutableBufferPointer { outBuffer in
                var rowStart = 0
                for _ in 0..<P.osImageHeight {
                    // Prepare input and output row buffers
                    let inRow = UnsafeBufferPointer(rebasing: inBuffer[rowStart..<rowStart + P.osImageWidth])
                    let outRow = UnsafeMutableBufferPointer(rebasing: outBuffer[rowStart..<rowStart + P.osImageWidth])
                    
                    calculateLine(P: P, inRow: inRow, outRow: outRow)
                    rowStart += P.osImageWidth
                    
                    if Task.isCancelled { break }
                }
            }
        }
        
        return result
    }
    
    /// Parallel calculation of Mandelbrot set
    nonisolated static func calculateParallel(P: DynamicParameters<PT>) async -> Matrix<MandelbrotResult> {
        // Create the output matrix
        var result = Matrix<MandelbrotResult>((P.osImageHeight, P.osImageWidth), defaultValue: .defaultValue)
        
        // Create the input matrix
        let cplxGrid = P.dimensions.mapScreenCoordinates(resolution: P.resolution, osSize: P.osSize)
            
        let inBuffer  = cplxGrid.grid.withUnsafeBufferPointer { $0 }
        let outBuffer = result.grid.withUnsafeMutableBufferPointer { $0 }
            
        await withTaskGroup(of: Void.self) { group in
            for y in 0..<P.imageHeight {
                let rowStart = cplxGrid.idx(y)
                let inRow  = SendableRow(buffer: UnsafeBufferPointer(rebasing: inBuffer[rowStart..<rowStart + P.osImageWidth]))
                let outRow = SendableMutableRow(buffer: UnsafeMutableBufferPointer(rebasing: outBuffer[rowStart..<rowStart + P.osImageWidth]))
                group.addTask {
                    calculateLine(P: P, inRow: inRow.buffer, outRow: outRow.buffer)
                }
            }
        }
        
        return result
    }
    
    /// Metal / GPU calculation of Mandelbrot set
    nonisolated static func calculateMetal(P: DynamicParameters<PT>) async -> Matrix<MandelbrotResult> {
        // Create the input matrix
        let cplxGrid = P.dimensions.mapScreenCoordinates(resolution: P.resolution, osSize: P.osSize)
        
        // Convert complex grid to Complex2 values
        let cplx2Grid = cplxGrid.grid.map { Complex2($0.toCplx()) }

        do {
            let metalCompute = try MetalCompute("mandelbrot")
            
            try metalCompute.addBuffer(cplx2Grid, .computeInputBuffer)
            try metalCompute.addBuffer(P.coloring.colorTable.ct.rgbaColors, .inputBuffer)
            metalCompute.addValue(P.computeParameters)
            
            // Compute Mandelbrot set
            // let result = try metalCompute.compute(RGBAColor.black.rgba)
            if let result = metalCompute.compute(MandelbrotResult.defaultValue) {
                // graphics.initFromColorArray(colors: result)
                return Matrix<MandelbrotResult>((P.osImageHeight, P.osImageWidth), grid: result)
            }
        }
        catch {
            print(error)
        }
        
        return Matrix<MandelbrotResult>((P.osImageHeight, P.osImageWidth), defaultValue: .defaultValue)
    }
}
