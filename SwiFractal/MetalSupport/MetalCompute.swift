//
//  MetalCompute.swift
//
//  Part of Metal64
//
//  Implementation of class MetalCompute
//
//  Created by Dirk Braner on 15.12.24.
//

import Metal


///
/// Class for Initializing and running Metal compute shaders from Swift
///
/// Usage:
///
/// 1. Create a MetalCompute object
/// 2. Add input parameters (arrays or scalar values) by using addBuffer() or addObject() APIs
/// 3. Call compute() method => returns array with results
///
class MetalCompute {

    // Error codes
    enum MetalError: Error {
        case deviceError(String)
        case libraryError(String)
        case commandQueueError(String)
        case commandBufferError(String)
        case computeEncoderError(String)
        case kernelFunctionError(String)
        case pipelineStateError(String)
        case addBufferError(String)
        case computeElementsError(String)
        case computeError(String)
    }
    
    // Buffer types (arrays)
    enum BufferType: Int {
        case computeInputBuffer = 1 // Buffer contains elements for parallel computing
        case inputBuffer = 2        // Buffer with input data (must not be used for parallel computing)
        case resultBuffer = 3       // Buffer with compute results. Must have the same size as the compute input buffers
    }
    
    let fncName: String             // Compute kernel function name
    var bufferIndex: Int = 0        // I/O buffer index
    var count: Int = -1             // Number of elements in compute argument buffer(s) and result buffer, -1 = no buffer
    
    var resultBuffer: MTLBuffer?    // Result buffer created by compute() method
    
    let device: MTLDevice
    let library: MTLLibrary
    let commandQueue: MTLCommandQueue
    let commandBuffer: MTLCommandBuffer
    let computeEncoder: MTLComputeCommandEncoder
    let kernelFunction: MTLFunction
    let pipelineState: MTLComputePipelineState
    
    ///
    /// Initialize metal device, create compute shaders
    ///
    /// Parameters:
    ///
    /// fncName - Name of kernel compute function
    /// count - Number of elements in compute input buffer
    ///
    init(_ fncName: String) throws {
        guard let device = MTLCreateSystemDefaultDevice() else { throw MetalError.deviceError("Cannot create device") }
        self.device = device
        
        guard let library = device.makeDefaultLibrary() else { throw MetalError.libraryError("Cannot create library") }
        self.library = library
        
        guard let commandQueue = device.makeCommandQueue() else { throw MetalError.commandQueueError("Cannnot create command queue") }
        self.commandQueue = commandQueue
        
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { throw MetalError.commandQueueError("Cannot create command buffer") }
        self.commandBuffer = commandBuffer
        
        guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else { throw MetalError.commandBufferError("Cannot create compute encoder") }
        self.computeEncoder = computeEncoder
        
        guard let kernelFunction = library.makeFunction(name: fncName) else { throw MetalError.kernelFunctionError("Cannot make kernel function") }
        self.kernelFunction = kernelFunction
        
        do {
            let pipelineState = try device.makeComputePipelineState(function: kernelFunction)
            self.pipelineState = pipelineState
        }
        catch {
            throw MetalError.pipelineStateError("Cannot make pipeline state")
        }
        
        self.fncName = fncName
    }
    
    ///
    /// Create a buffer as a copy of specified array and add buffer to compute encoder
    ///
    /// Parameters:
    ///
    /// values - Array with initial buffer values
    /// bufferType - Type of buffer: .computeInputBuffer, .inputBuffer or .resultBuffer
    ///
    /// Throw's exception on error
    ///
    func addBuffer<T>(_ value: [T], _ bufferType: BufferType = .computeInputBuffer) throws where T: BitwiseCopyable {
        var bufferSize: Int = 0
        
        if bufferType == .computeInputBuffer || bufferType == .resultBuffer {
            // Buffer used as input for parallel computation or to store computation results
            if count > 0 && value.count != count { throw MetalError.addBufferError("Element count mismatch") }
            if count == -1 { count = value.count }
            bufferSize = MemoryLayout<T>.size * count
        }
        else if bufferType == .inputBuffer {
            // Input data buffer
            bufferSize = MemoryLayout<T>.size * value.count
        }
        else {
            throw MetalError.addBufferError("Invalid buffer type")
        }

        if let buffer = device.makeBuffer(bytes: value, length: bufferSize, options: .storageModeShared) {
            computeEncoder.setBuffer(buffer, offset: 0, index: bufferIndex)
            bufferIndex += 1
            if bufferType == .resultBuffer {
                resultBuffer = buffer
            }
        }
        else {
            throw MetalError.addBufferError("Cannot create buffer")
        }
    }
    
    ///
    /// Add a value or an object to compute encoder
    ///
    /// Parameters:
    ///
    /// value - A numeric value of type Int, Float, Float2 or Double
    ///
    /// Either true or false
    ///
    func addObject<T>(_ value: T) where T: BitwiseCopyable {
        var v = value
        computeEncoder.setBytes(&v, length: MemoryLayout<T>.stride, index: bufferIndex)
        bufferIndex += 1
    }
       
    ///
    /// Call kernel function
    ///
    /// Parameters:
    ///
    /// initValue - Initial value of type T for result buffer
    ///
    /// Return values:
    ///
    /// Unsafe buffer pointer of type T pointing to results
    /// Throws exception on error
    ///
    func compute<T>(_ initValue: T, _ resCount: Int = -1) throws -> UnsafeBufferPointer<T> where T: BitwiseCopyable {
        do {
            guard resCount > 0 || count > 0 else {
                throw MetalError.computeElementsError("Element count = 0")
            }
            
            if count == -1 {
                if resCount == -1 {
                    throw MetalError.computeElementsError("Element count for results must be greater than 0")
                }
                count = resCount
            }
            else if (count > 0 && resCount != -1 && resCount != count) {
                throw MetalError.computeElementsError("Element count mismatch")
            }
            
            // Add the result buffer
            try addBuffer(Array(repeating: initValue, count: count), .resultBuffer)
            
            // Calculate number of worker threads
            let gridSize = MTLSizeMake(count, 1, 1)
            let threadCount = min(pipelineState.maxTotalThreadsPerThreadgroup, count)
            let threadGroupSize = MTLSizeMake(threadCount, 1, 1)
            
            // Start computing and wait for results
            computeEncoder.setComputePipelineState(pipelineState)
            computeEncoder.dispatchThreads(gridSize, threadsPerThreadgroup: threadGroupSize)
            computeEncoder.endEncoding()
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
            
            // Convert result buffer
            let converted = resultBuffer!.contents().bindMemory(to: T.self, capacity: count)
            return UnsafeBufferPointer(start: converted, count: count)
        } catch {
            computeEncoder.endEncoding()
            throw error
        }
    }
}
