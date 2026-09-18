//
//  LinearBuffer.swift
//  SwiFractal
//
//  Created by Dirk Braner on 06.08.26.
//

import Foundation
import Accelerate


///
/// Class for linear buffer
///
final class LinearBuffer<Element: Sendable>: @unchecked Sendable {
    let pointer: UnsafeMutableBufferPointer<Element>
    let width: Int
    let height: Int
    var size: Int { width * height }
    
    /// Initialize line buffer
    /// - Parameters:
    ///   - width: Width
    ///   - height: Height
    ///   - initialValue: Initial buffer value
    init(width: Int, height: Int, initialValue: Element) {
        self.width = width
        self.height = height
        self.pointer = .allocate(capacity: width * height)
        pointer.initialize(repeating: initialValue)
    }

    deinit {
        pointer.deinitialize()
        pointer.deallocate()
    }
    
    /// Return line index
    /// - Parameter y: Row
    /// - Returns: Offset of start of row in buffer
    @inline(__always)
    func idx(_ y: Int) -> Int { y * width }
    
    /// Return index of point
    /// - Parameters:
    ///   - x: Column
    ///   - y: Row
    /// - Returns: Offset of point in buffer
    @inline(__always)
    func idx(_ x: Int, _ y: Int) -> Int { y * width + x }
}
