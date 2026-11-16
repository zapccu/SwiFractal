//
//  FractalCalculation.swift
//  SwiFractal
//
//  Created by Dirk Braner on 31.07.26.
//
//  Implement calculation functions.
//

import Foundation
import SwiftUI
import SwiftMPx
import Metal64
import MetalCompute


///
/// Sendable read-only buffer
///
struct SendableRow<T>: @unchecked Sendable {
    let buffer: UnsafeBufferPointer<T>
}

///
/// Sendable read/write buffer
///
struct SendableMutableRow<T>: @unchecked Sendable {
    let buffer: UnsafeMutableBufferPointer<T>
}

/// Combined calculation result
typealias CombinedResult = (result: Matrix<MandelbrotResult>?, info: CalculationInfo)

///
/// Wrapper for fractal calculations
///
enum FractalCalculation<PT: FractalData> {
    
    typealias RT = PT.RT
    typealias CT = RT.CT
        
    /// Calculation function
    typealias CalculationFunction = @concurrent @Sendable (DynamicParameters<PT>) async -> CombinedResult
    
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
        guard P.supportedCalculationMethods.contains(method) else { return nil }
        return calculationFunctions[method]
    }
    
    /// Iterate an array of complex points
    /// - Parameters:
    ///   - P: Dynamic calculation parameters
    ///   - progress: Calculation progress
    ///   - inRow: Array of complex points
    ///   - outRow: Array of calculation results
    nonisolated static func calculateChunk(P: DynamicParameters<PT>,
                                           progress: CalculationProgress,
                                           inRow: UnsafeBufferPointer<CT>,
                                           outRow: UnsafeMutableBufferPointer<MandelbrotResult>)
    {
        // Initial iteration value mapper
        let mapping = P.initial
        
        let count = outRow.count
        let batch = 4096
        
        var start = 0
        while start < count {
            let end = min(start + batch, count)
            for i in start..<end {
                // Check if point is already calculated
                guard outRow[i].flags == .calculate else { continue }
                
                // Initial values of iteration
                let (z0, c, d0) = mapping.values(for: inRow[i])
                
                // Calculate point
                outRow[i] = calculatePointZ2(Z0: z0, C: c, D0: d0, P: P)
            }
            progress.add(end - start)
            if Task.isCancelled { return }
            start = end
        }
    }
    
    /// Iterate an array of complex points using perturbation method and series approximation
    /// - Parameters:
    ///   - P: Dynamic calculation parameters
    ///   - progress: Calculation progress
    ///   - refOrbit: Reference orbit
    ///   - sa: Series approximation coefficients
    ///   - inRow: Array of delta values to reference point
    ///   - outRow: Array of calculated results
    /// - Returns: Tuple (new reference point, number of glitches)
    nonisolated static func calculateChunkPT(P: DynamicParameters<PT>, progress: CalculationProgress,
                                             refOrbit: [Cplx], sa: SACoefficients,
                                             inRow: UnsafeBufferPointer<CT>,
                                             outRow: UnsafeMutableBufferPointer<MandelbrotResult>) -> (CT, Int)
    {
        let refPoint = P.dimensions.refPoint
        var newRefPoint: CT = .zero(precision: P.dimensions.precision.bits)
        var maxGlitchIterationCount: Double = 0

        var glitchCount: Int = 0

        for (i, inElement) in zip(inRow.indices, inRow) where outRow[i].flags == .calculate {
            var result = calculatePointZ2PT(deltaC: inElement.toCplx(), refC: refPoint, refOrbit: refOrbit, sa: sa, P: P)
            if result.flags == .error {
                // Point must be recalculated
                result.flags = .calculate
                glitchCount += 1
                
                if result.smoothIter > maxGlitchIterationCount {
                    newRefPoint = refPoint + inElement
                    maxGlitchIterationCount = result.smoothIter
                }
            }
            outRow[i] = result
        }
        
        return (newRefPoint, glitchCount)
    }

    /// Iterate an array of complex points. Skip specified number of points.
    /// - Parameters:
    ///   - P: Dynamic calculation parameters
    ///   - inRow: Array of complex points
    ///   - outRow: Array of calculation results
    ///   - skip: Number of points to skip. Default = 1
    nonisolated static func calculateChunkFast(P: DynamicParameters<PT>,
                                              inRow: UnsafeBufferPointer<CT>,
                                              outRow: UnsafeMutableBufferPointer<MandelbrotResult>,
                                              skip: Int = 1)
    {
        // Initial value mapper
        let mapper = P.initial
        
        for i in stride(from: 0, to: inRow.count, by: skip + 1) {
            let (z0, c, d0) = mapper.values(for: inRow[i])
            outRow[i] = calculatePointZ2(Z0: z0, C: c, D0: d0, P: P)
            
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
    /// - Returns: Combined calculation result
    @concurrent nonisolated static func calculateSequential(P: DynamicParameters<PT>) async -> CombinedResult {
        // Map screen coordinates to absolute complex coordinates
        let inBuffer = P.dimensions.mapScreenCoordinates(resolution: P.resolution, osSize: P.osSize)
        
        // Create result buffer
        let outBuffer = LinearBuffer<MandelbrotResult>(width: P.osImageWidth, height: P.osImageHeight, initialValue: .initialValue)
        
        // Total number of points to be calculated
        let totalCount = outBuffer.pointer.count   // = osImageWidth * osImageHeight
        
        // Reset the calculation progress
        let progress = P.progress
        progress.reset(total: totalCount)
        progress.pass(1)

        // Create sendable buffers for current line
        let inChunk  = SendableRow(buffer: UnsafeBufferPointer(rebasing: inBuffer.pointer[0..<totalCount]))
        let outChunk = SendableMutableRow(buffer: UnsafeMutableBufferPointer(rebasing: outBuffer.pointer[0..<totalCount]))

        // Initial value mapper
        let mapper = P.initial
        
        var errorCount: Int = 0
        
        // Update progress batch size
        let batch = 4096
        
        for start in stride(from: 0, to: totalCount, by: batch) {
            let end = min(start + batch, totalCount)
            
            // Calculate points one by one
            for i in start..<end {
                guard outChunk.buffer[i].flags == .calculate else { continue }
                
                let (z0, c, d0) = mapper.values(for: inChunk.buffer[i])
                let result = calculatePointZ2(Z0: z0, C: c, D0: d0, P: P)
                if result.flags == .error {
                    errorCount += 1
                }
                
                outChunk.buffer[i] = result
            }
            
            // Update progress
            progress.add(end - start)
            
            // Stop the calculation if user pressed the cancel button
            if Task.isCancelled { return CombinedResult(nil, CalculationInfo(state: .cancelled)) }
        }
            
        return CombinedResult(
            Matrix<MandelbrotResult>((P.osImageHeight, P.osImageWidth), grid: Array(outBuffer.pointer)),
            CalculationInfo(state: .completed, extendedInfo: P.extendedInfo, errorCount: errorCount)
        )
    }

    /// Sequential calculation of Mandelbrot set using perturbation algorithm
    /// - Parameters:
    ///   - P: Calculation parameters
    /// - Returns: Combined calculation result
    @concurrent nonisolated static func calculateSequentialPT(P: DynamicParameters<PT>) async -> CombinedResult {
        var refPoint: CT = P.dimensions.refPoint
                
        // Create result buffer
        let outBuffer = LinearBuffer<MandelbrotResult>(width: P.osImageWidth, height: P.osImageHeight, initialValue: .initialValue)

        // Total number of points to be calculated
        let totalCount = outBuffer.pointer.count   // = osImageWidth * osImageHeight

        // Create sendable output buffer
        let outChunk = SendableMutableRow(buffer: UnsafeMutableBufferPointer(rebasing: outBuffer.pointer[0..<totalCount]))

        // Progress counter
        let progress = P.progress
        
        // Maximum number of Perturbation passes
        let maxP: Int = P.settings.perturbationPasses

        // Counter for glitches in Perturbation iteration pass
        var glitchCount: Int = 0
        
        // Perturbation passes
        for p in 0..<maxP {
            // Reset progress counter with each perturbation pass
            progress.reset(total: totalCount)
            
            // Set current calculation pass number
            progress.pass(p + 1)

            var sa: SACoefficients = .initial           // Series approximation coefficients
            var maxGlitchIterationCount: Double = 0     // Take the point with the highest iteration count as new refPoint
            var newRefPoint: CT = refPoint              // New reference point
            
            glitchCount = 0

            // Map screen coordinates to relative complex coordinates (array of ΔC values)
            let inBuffer = P.dimensions.mapDeltaScreenCoordinates(refPoint: refPoint, resolution: P.resolution, osSize: P.osSize)

            // Compute reference orbit
            let refOrbit = generateReferenceOrbit(refPoint: refPoint, limits: P.limits.parameters)
            
            // Compute series approximation coefficients for reference orbit
            if P.settings.useSeriesApproximation {
                sa = computeSACoefficients(refOrbit: refOrbit, dC: P.minPixelDistance.asDouble)
            }

            // Create sendable input buffer
            let inChunk = SendableRow(buffer: UnsafeBufferPointer(rebasing: inBuffer.pointer[0..<totalCount]))
        
            // Update progress batch size
            let batch = 4096
            
            for start in stride(from: 0, to: totalCount, by: batch) {
                let end = min(start + batch, totalCount)
                
                for i in start..<end {
                    guard outChunk.buffer[i].flags == .calculate else { continue }
                    
                    var result = calculatePointZ2PT(deltaC: inChunk.buffer[i].toCplx(), refC: refPoint, refOrbit: refOrbit, sa: sa, P: P)
                    
                    if result.flags == .error {
                        // Point must be recalculated
                        result.flags = .calculate
                        glitchCount += 1
                        
                        if result.smoothIter > maxGlitchIterationCount {
                            newRefPoint = refPoint + inChunk.buffer[i]
                            maxGlitchIterationCount = result.smoothIter
                        }
                    }
                    
                    outChunk.buffer[i] = result
                }

                // Update progress
                progress.add(end - start)
                
                // Calculation cancelled by customer via UI button
                if Task.isCancelled { return (nil, CalculationInfo(state: .cancelled)) }
            }

            debugPrint("Perturbation pass \(p): Number of glitches = \(glitchCount)")

            // Stop the calculation if number of glitches is 0
            if glitchCount == 0 { break }
            
            // Use new reference point for next perturbation pass
            refPoint = newRefPoint
        }
        
        // Fix remaining glitches.
        // We cannot use calculateSequential() or calculateParallel() because existing results must be preserved.
        if glitchCount > 0 && P.settings.fixGlitches {
            // Reset progress counter
            progress.reset(total: totalCount)
            
            // Final calculation pass
            progress.pass(maxP + 1)
            
            // Map screen coordinates to absolute complex coordinates
            let inBuffer = P.dimensions.mapScreenCoordinates(resolution: P.resolution, osSize: P.osSize)

            // Create sendable input buffer. Keep output buffer with existing results
            let inChunk  = SendableRow(buffer: UnsafeBufferPointer(rebasing: inBuffer.pointer[0..<totalCount]))

            calculateChunk(P: P, progress: progress, inRow: inChunk.buffer, outRow: outChunk.buffer)
            
            glitchCount = 0     // No more glitches
        }
                
        return CombinedResult(
            Matrix<MandelbrotResult>((P.osImageHeight, P.osImageWidth), grid: Array(outBuffer.pointer)),
            CalculationInfo(state: .completed, extendedInfo: P.extendedInfo, errorCount: glitchCount)
        )
    }

    /// Parallel calculation of Mandelbrot set
    /// - Parameters:
    ///   - P: Calculation parameters
    /// - Returns: Matrix of calculation results in dimensions (height, width)
    nonisolated static func calculateParallel(P: DynamicParameters<PT>) async -> CombinedResult {
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

        // Reset calculation progress
        let progress = P.progress
        progress.reset(total: totalCount)
        progress.pass(1)

        await withTaskGroup(of: Void.self) { group in
            var start = 0
            while start < totalCount {
                let end = min(start + chunkSize, totalCount)

                let inChunk  = SendableRow(buffer: UnsafeBufferPointer(rebasing: inBuffer.pointer[start..<end]))
                let outChunk = SendableMutableRow(buffer: UnsafeMutableBufferPointer(rebasing: outBuffer.pointer[start..<end]))

                group.addTask(priority: .high) {
                    calculateChunk(P: P, progress: progress, inRow: inChunk.buffer, outRow: outChunk.buffer)
                }

                start = end
            }
        }
        
        if Task.isCancelled {
            return CombinedResult(nil, CalculationInfo(state: .cancelled))
        }

        return CombinedResult(
            Matrix<MandelbrotResult>((P.osImageHeight, P.osImageWidth), grid: Array(outBuffer.pointer)),
            CalculationInfo(state: .completed, extendedInfo: P.extendedInfo)
        )
    }
    
    /// Metal / GPU calculation of Mandelbrot set.
    /// Calculation progress update is not supported.
    /// - Parameters:
    ///   - P: Calculation parameters
    /// - Returns: Matrix of calculation results in dimensions (height, width)
    nonisolated static func calculateMetal(P: DynamicParameters<PT>) async -> CombinedResult {
        // Create the input buffer
        let cplx2Grid: LinearBuffer<Complex2> = P.dimensions.asDouble.mapScreenCoordinates(
            resolution: P.resolution, osSize: P.osSize)
        
        do {
            let metal = try MetalCompute()
            var kernel: ComputeKernel           // Compute kernel
            var result: [MandelbrotResult]      // Calculation result
            
            if P.initial.kind == .mandelbrot {
                kernel = try metal.kernel("mandelbrot")

                // Compute the Mandelbrot set
                result = try await kernel.run(cplx2Grid.pointer, P, count: cplx2Grid.size)
            }
            else {
                kernel = try metal.kernel("julia")
                let juliaPoint = P.initial.constant.toCplx()
                
                // Compute the Julia set
                result = try await kernel.run(cplx2Grid.pointer, juliaPoint, P, count: cplx2Grid.size)
            }
            
            return CombinedResult(
                Matrix<MandelbrotResult>((P.osImageHeight, P.osImageWidth), grid: result),
                CalculationInfo(state: .completed, extendedInfo: P.extendedInfo)
            )
        }
        catch {
            debugPrint(error)
            return CombinedResult(nil, CalculationInfo(state: .error, extendedInfo: P.extendedInfo, message: error.localizedDescription))
        }
    }
    
}
