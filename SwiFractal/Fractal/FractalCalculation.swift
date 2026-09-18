//
//  FractalCalculation.swift
//  SwiFractal
//
//  Created by Dirk Braner on 31.07.26.
//

import Foundation
import SwiftUI
import SwiftMPx
import Metal64


struct SendableRow<T>: @unchecked Sendable {
    let buffer: UnsafeBufferPointer<T>
}

struct SendableMutableRow<T>: @unchecked Sendable {
    let buffer: UnsafeMutableBufferPointer<T>
}

///
/// Wrapper for fractal calculations
/// 
enum FractalCalculation<PT: IterationData> {
    
    typealias RT = PT.RT
    typealias CT = RT.CT
    
    typealias CalculationFunction = @Sendable (DynamicParameters<PT>) async -> Matrix<MandelbrotResult>
    
    /// Dictionary with calculation functions for calculation methods
    nonisolated static var calculationFunctions: [CalculationMethod: CalculationFunction] {
        [
            .sequential:    calculateLineByLine,
            .parallel:      calculateParallel,
            .metalcompute:  calculateMetal,
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
    nonisolated static func calculateLine(P: DynamicParameters<PT>,
        inRow: UnsafeBufferPointer<CT>, outRow: UnsafeMutableBufferPointer<MandelbrotResult>
    ) {
        for i in inRow.indices {
            let (z0, c) = P.fp.initialValues(v: inRow[i])
            outRow[i] = calculatePointZ2(Z0: z0, C: c, P: P)
        }
    }
    
    /// Iterate an array of complex points. Only every second point is calculated
    /// - Parameters:
    ///   - P: Dynamic calculation parameters
    ///   - inRow: Array of complex points
    ///   - outRow: Array of calculation results
    ///   - skip: Number of points to skip. Default = 1
    nonisolated static func calculateLineFast(P: DynamicParameters<PT>,
                                              inRow: UnsafeBufferPointer<CT>,
                                              outRow: UnsafeMutableBufferPointer<MandelbrotResult>,
                                              skip: Int = 1)
    {
        for i in stride(from: 0, to: inRow.count, by: skip + 1) {
            let (z0, c) = P.fp.initialValues(v: inRow[i])
            outRow[i] = calculatePointZ2(Z0: z0, C: c, P: P)
            for j in 1...skip {
                let n = i + j
                if n < inRow.count {
                    outRow[n] = outRow[i]
                }
            }
        }
    }
    
    /// Sequential calculation of Mandelbrot set line by line
    /// - Parameters:
    ///   - P: Calculation parameters
    /// - Returns: Matrix of calculation results in dimensions (height, width)
    nonisolated static func calculateLineByLine(P: DynamicParameters<PT>) async -> Matrix<MandelbrotResult> {
        // Create the output matrix
        let inBuffer: LinearBuffer<CT> = P.fp.dimensions.mapScreenCoordinates(resolution: P.resolution, osSize: P.osSize)
        let outBuffer = LinearBuffer<MandelbrotResult>(width: P.osImageWidth, height: P.osImageHeight, initialValue: .defaultValue)
        
        let totalCount = outBuffer.pointer.count   // = osImageWidth * osImageHeight
        let chunkSize  = P.osImageWidth

        var start = 0
        
        // We split the calculation into lines to make the process interruptable
        for _ in 0..<P.osImageHeight {
            let end = min(start + chunkSize, totalCount)

            let inChunk  = SendableRow(buffer: UnsafeBufferPointer(rebasing: inBuffer.pointer[start..<end]))
            let outChunk = SendableMutableRow(buffer: UnsafeMutableBufferPointer(rebasing: outBuffer.pointer[start..<end]))

            calculateLine(P: P, inRow: inChunk.buffer, outRow: outChunk.buffer)
            
            start += chunkSize
            
            if Task.isCancelled { break }
        }
        
        return Matrix<MandelbrotResult>((P.osImageHeight, P.osImageWidth), grid: Array(outBuffer.pointer))
    }
    
    /// Parallel calculation of Mandelbrot set
    /// - Parameters:
    ///   - P: Calculation parameters
    /// - Returns: Matrix of calculation results in dimensions (height, width)
    nonisolated static func calculateParallel(P: DynamicParameters<PT>) async -> Matrix<MandelbrotResult> {
        let inBuffer: LinearBuffer<CT> = P.fp.dimensions.mapScreenCoordinates(resolution: P.resolution, osSize: P.osSize)
        let outBuffer = LinearBuffer<MandelbrotResult>(width: P.osImageWidth, height: P.osImageHeight, initialValue: .defaultValue)

        let totalCount = outBuffer.pointer.count   // = osImageWidth * osImageHeight
        let coreCount = P.settings.cpuCount
        let oversubscriptionFactor = 2
        let targetChunkCount = coreCount * oversubscriptionFactor
        let chunkSize = max(1, (totalCount + targetChunkCount - 1) / targetChunkCount)

        await withTaskGroup(of: Void.self) { group in
            var start = 0
            while start < totalCount {
                let end = min(start + chunkSize, totalCount)

                let inChunk  = SendableRow(buffer: UnsafeBufferPointer(rebasing: inBuffer.pointer[start..<end]))
                let outChunk = SendableMutableRow(buffer: UnsafeMutableBufferPointer(rebasing: outBuffer.pointer[start..<end]))

                group.addTask {
                    calculateLine(P: P, inRow: inChunk.buffer, outRow: outChunk.buffer)
                }

                start = end
            }
        }

        return Matrix<MandelbrotResult>((P.osImageHeight, P.osImageWidth), grid: Array(outBuffer.pointer))
    }
    
    /// Metal / GPU calculation of Mandelbrot set
    /// - Parameters:
    ///   - P: Calculation parameters
    /// - Returns: Matrix of calculation results in dimensions (height, width)
    nonisolated static func calculateMetal(P: DynamicParameters<PT>) async -> Matrix<MandelbrotResult> {
        // Create the input matrix
        let cplx2Grid: LinearBuffer<Complex2> = P.fp.dimensions.asDouble.mapScreenCoordinates(resolution: P.resolution, osSize: P.osSize)

        do {
            let metalCompute = try MetalCompute("mandelbrot", cplx2Grid.size)
            
            try metalCompute.prepareComputeEncoder()
            
            try metalCompute.addBuffer(cplx2Grid.pointer, .inputBuffer)
            try metalCompute.addStruct(P.computeParameters)
            try metalCompute.addValue(P.potential)
            
            // Compute Mandelbrot set.
            // Result is an array of type MandelbrotResultMtl. It must be converted to an array of type MandelbrotResult
            // before the result matrix is created.
            if let result = metalCompute.compute(MandelbrotResult.defaultValue.mandelbrotResultMtl) {
                return Matrix<MandelbrotResult>((P.osImageHeight, P.osImageWidth), grid: result.map { $0.mandelbrotResult } )
            }
        }
        catch {
            print(error)
        }
        
        return Matrix<MandelbrotResult>((P.osImageHeight, P.osImageWidth), defaultValue: .defaultValue)
    }
}
