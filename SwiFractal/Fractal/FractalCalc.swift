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
enum FractalCalculation<PT: FractalData> {
    
    typealias RT = PT.RT
    typealias CT = RT.CT
    
    typealias CalculationFunction = @Sendable (DynamicParameters<PT>) async -> Matrix<MandelbrotResult>
    
    /// Dictionary with calculation functions for calculation methods
    nonisolated static var calculationFunctions: [CalculationMethod: CalculationFunction] {
        [
            .sequential:                calculateSequential,
            .sequentialPerturbation:    calculateSequentialPT,
            .parallel:                  calculateParallel,
            .metalcompute:              calculateMetal,
        ]
    }
    
    /// Return calculation function for specified calculation method
    /// - Parameters:
    ///   - method: Calculation method (sequential, parallel, metalcompute)
    ///   - P: Fractal parameters
    /// - Returns: Calculation function or nil if method is not supported
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
    nonisolated static func calculateChunk(P: DynamicParameters<PT>,
                                           inRow: UnsafeBufferPointer<CT>,
                                           outRow: UnsafeMutableBufferPointer<MandelbrotResult>)
    {
        let mapping = P.initial
        
        for i in inRow.indices {
            guard outRow[i].flags == .calculate else { continue }
            
            let (z0, c) = mapping.values(for: inRow[i])
            //let (z0, c) = P.fp.initialValues(v: inRow[i])
            outRow[i] = calculatePointZ2(Z0: z0, C: c, P: P)
        }
    }
    
    /// Iterate an array of complex points using perturbation method and series approximation
    /// - Parameters:
    ///   - P: Dynamic calculation parameters
    ///   - refOrbit: Reference orbit
    ///   - sa: Series approximation coefficients
    ///   - inRow: Array of delta values to reference point
    ///   - outRow: Array of calculated results
    /// - Returns: Tuple (new reference point, number of glitches)
    nonisolated static func calculateLinePT(P: DynamicParameters<PT>, refOrbit: [Cplx], sa: SACoefficients,
                                            inRow: UnsafeBufferPointer<CT>,
                                            outRow: UnsafeMutableBufferPointer<MandelbrotResult>) -> (CT, Int)
    {
        let refPoint = P.dimensions.refPoint
        var newRefPoint: CT = .zero(precision: P.dimensions.precision.bits)
        var glitches: Int = 0
        var maxGlitchIterationCount: Double = 0

        for i in inRow.indices {
            if outRow[i].flags == .calculate {
                outRow[i] = calculatePointZ2PT(deltaC: inRow[i].toCplx(), refOrbit: refOrbit, sa: sa, P: P)
                if outRow[i].flags == .error {
                    // Point must be recalculated
                    outRow[i].flags = .calculate
                    glitches += 1
                    
                    if outRow[i].smoothIter > maxGlitchIterationCount {
                        newRefPoint = refPoint + inRow[i]
                        maxGlitchIterationCount = outRow[i].smoothIter
                    }
                }
            }
        }
        
        return (newRefPoint, glitches)
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
        // Initial value mapper
        let mapper = P.initial
        
        for i in stride(from: 0, to: inRow.count, by: skip + 1) {
            let (z0, c) = mapper.values(for: inRow[i])
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
    nonisolated static func calculateSequential(P: DynamicParameters<PT>, ) async -> Matrix<MandelbrotResult> {
        // Map screen coordinates to absolute complex coordinates
        let inBuffer = P.dimensions.mapScreenCoordinates(resolution: P.resolution, osSize: P.osSize)
        
        // Create result buffer
        let outBuffer = LinearBuffer<MandelbrotResult>(width: P.osImageWidth, height: P.osImageHeight, initialValue: .initialValue)
        
        // Total number of points to be calculated
        let totalCount = outBuffer.pointer.count   // = osImageWidth * osImageHeight

        // Create sendable buffers for current line
        let inChunk  = SendableRow(buffer: UnsafeBufferPointer(rebasing: inBuffer.pointer[0..<totalCount]))
        let outChunk = SendableMutableRow(buffer: UnsafeMutableBufferPointer(rebasing: outBuffer.pointer[0..<totalCount]))

        // Initial value mapper
        let mapper = P.initial
        
        // Split the calculation into lines to make the process interruptable
        for i in 0..<totalCount {
            guard outChunk.buffer[i].flags == .calculate else { continue }
            
            let (z0, c) = mapper.values(for: inChunk.buffer[i])
            outChunk.buffer[i] = calculatePointZ2(Z0: z0, C: c, P: P)

            // Stop the calculation if user pressed the cancel button
            if Task.isCancelled { break }
        }

        return Matrix<MandelbrotResult>((P.osImageHeight, P.osImageWidth), grid: Array(outBuffer.pointer))
    }

    /// Sequential calculation of Mandelbrot set using perturbation algorithm
    /// - Parameters:
    ///   - P: Calculation parameters
    /// - Returns: Matrix of calculation results in dimensions (height, width)
    nonisolated static func calculateSequentialPT(P: DynamicParameters<PT>) async -> Matrix<MandelbrotResult> {
        var refPoint: CT = P.dimensions.refPoint
                
        // Create result buffer
        let outBuffer = LinearBuffer<MandelbrotResult>(width: P.osImageWidth, height: P.osImageHeight, initialValue: .initialValue)

        // Total number of points to be calculated
        let totalCount = outBuffer.pointer.count   // = osImageWidth * osImageHeight
        
        var glitches: Int = 0  // Total number of glitches in current pass
        
        // Perturbation passes
        for p in 0..<P.settings.perturbationPasses {
            var sa: SACoefficients = .initial           // Series approximation coefficients
            var maxGlitchIterationCount: Double = 0     // Take the point with the highest iteration count as new refPoint
            var newRefPoint: CT = refPoint              // New reference point
            var bCancelled: Bool = false                // Calculation cancelled by user
            
            glitches = 0

            // Map screen coordinates to relative complex coordinates (array of ΔC values)
            let inBuffer = P.dimensions.mapDeltaScreenCoordinates(refPoint: refPoint, resolution: P.resolution,
                                                                     osSize: P.osSize)

            // Compute reference orbit
            let refOrbit = generateReferenceOrbit(refPoint: refPoint, limits: P.limits.parameters)
            
            // Compute series approximation coefficients for reference orbit
            if P.settings.useSeriesApproximation {
                sa = computeSACoefficients(refOrbit: refOrbit, dC: P.minPixelDistance.asDouble)
            }

            // Create sendable buffers
            let inChunk  = SendableRow(buffer: UnsafeBufferPointer(rebasing: inBuffer.pointer[0..<totalCount]))
            let outChunk = SendableMutableRow(buffer: UnsafeMutableBufferPointer(rebasing: outBuffer.pointer[0..<totalCount]))
            
            for i in 0..<totalCount {
                guard outChunk.buffer[i].flags == .calculate else { continue }

                var result = calculatePointZ2PT(deltaC: inChunk.buffer[i].toCplx(), refOrbit: refOrbit, sa: sa, P: P)

                if result.flags == .error {
                    // Point must be recalculated
                    result.flags = .calculate
                    glitches += 1
                    
                    if result.smoothIter > maxGlitchIterationCount {
                        newRefPoint = refPoint + inChunk.buffer[i]
                        maxGlitchIterationCount = result.smoothIter
                    }
                }
                
                outChunk.buffer[i] = result
                
                if Task.isCancelled {
                    bCancelled = true
                    break
                }
            }

            debugPrint("Perturbation pass \(p): Number of glitches = \(glitches)")

            // Stop the calculation if user pressed the cancel button or number of glitches is 0
            if glitches == 0 || bCancelled { break }
            
            // Use new reference point for next perturbation pass
            refPoint = newRefPoint
        }
        
        // Fix remaining glitches
        if glitches > 0 && P.settings.fixGlitches {
            // Map screen coordinates to absolute complex coordinates
            let inBuffer = P.dimensions.mapScreenCoordinates(resolution: P.resolution, osSize: P.osSize)

            // Create sendable buffers
            let inChunk  = SendableRow(buffer: UnsafeBufferPointer(rebasing: inBuffer.pointer[0..<totalCount]))
            let outChunk = SendableMutableRow(buffer: UnsafeMutableBufferPointer(rebasing: outBuffer.pointer[0..<totalCount]))

            calculateChunk(P: P, inRow: inChunk.buffer, outRow: outChunk.buffer)
        }
        
        return Matrix<MandelbrotResult>((P.osImageHeight, P.osImageWidth), grid: Array(outBuffer.pointer))
    }

    /// Parallel calculation of Mandelbrot set
    /// - Parameters:
    ///   - P: Calculation parameters
    /// - Returns: Matrix of calculation results in dimensions (height, width)
    nonisolated static func calculateParallel(P: DynamicParameters<PT>) async -> Matrix<MandelbrotResult> {
        // Create input and output buffers
        let inBuffer: LinearBuffer<CT> = P.dimensions.mapScreenCoordinates(resolution: P.resolution, osSize: P.osSize)
        let outBuffer = LinearBuffer<MandelbrotResult>(width: P.osImageWidth, height: P.osImageHeight, initialValue: .initialValue)

        // Total number of points to be calculated
        let totalCount = outBuffer.pointer.count   // = osImageWidth * osImageHeight

        // Number of CPU cores to be used by calculation considering oversubscription
        let coreCount = P.settings.cpuCount
        let oversubscriptionFactor = P.settings.oversubscription

        // Calculate number of chunks and chunk size.
        // Chunk size depends on CPU cores and oversubscription factor
        let targetChunkCount = coreCount * oversubscriptionFactor
        let chunkSize = max(1, (totalCount + targetChunkCount - 1) / targetChunkCount)
        
        debugPrint("CPUs: \(coreCount), chunkSize: \(chunkSize), targetChunkCount: \(targetChunkCount), oversubscriptionFactor: \(oversubscriptionFactor)")

        await withTaskGroup(of: Void.self) { group in
            var start = 0
            while start < totalCount {
                let end = min(start + chunkSize, totalCount)

                let inChunk  = SendableRow(buffer: UnsafeBufferPointer(rebasing: inBuffer.pointer[start..<end]))
                let outChunk = SendableMutableRow(buffer: UnsafeMutableBufferPointer(rebasing: outBuffer.pointer[start..<end]))

                group.addTask(priority: .high) {
                    calculateChunk(P: P, inRow: inChunk.buffer, outRow: outChunk.buffer)
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
        // Create the input buffer
        let cplx2Grid: LinearBuffer<Complex2> = P.dimensions.asDouble.mapScreenCoordinates(resolution: P.resolution, osSize: P.osSize)

        do {
            let metalCompute = try MetalCompute("mandelbrot", cplx2Grid.size)
            
            try metalCompute.prepareComputeEncoder()
            
            try metalCompute.addBuffer(cplx2Grid.pointer, .inputBuffer)
            try metalCompute.addStruct(P.computeParameters)
            try metalCompute.addValue(P.potential)
            
            // Compute the Mandelbrot set.
            // Result is an array of type MandelbrotResultMtl. It must be converted to an array of type MandelbrotResult
            // before the result matrix is created.
            if let result = metalCompute.compute(MandelbrotResult.initialValue.mandelbrotResultMtl) {
                return Matrix<MandelbrotResult>((P.osImageHeight, P.osImageWidth), grid: result.map { $0.mandelbrotResult } )
            }
        }
        catch {
            print(error)
        }
        
        return Matrix<MandelbrotResult>((P.osImageHeight, P.osImageWidth), defaultValue: .defaultValue)
    }
}
