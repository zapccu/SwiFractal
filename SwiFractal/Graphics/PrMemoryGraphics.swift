//
//  PrMemoryGraphics.swift
//  SwiFractal
//
//  Created by Dirk Braner on 27.09.26.
//

import Foundation


///
/// Protocol for memory based graphics
///
protocol MemoryGraphicsProtocol : GraphicsProtocol {
    
    /// Number of bytes per line including padding bytes
    var bytesPerLine: Int { get }

    /// Index of current drawing position
    var index: Int { get set }
    
    var lastIndex: Int { get }

    /// Return index of specified coordinates
    func getIndex(_ x: Int, _ y: Int) -> Int
    
    /// Return index of specified point
    func getIndex(_ point: IPoint) -> Int
    
    /// Return index of specified row
    func getRowIndex(_ y: Int) -> Int
    
    /// Set pixel at index
    func setPixel(_ index: Int, color: RGBAColor?)
    
    /// Set pixel at coordinates
    func setPixel(_ x: Int, _ y: Int, color: RGBAColor?)
    
}

extension MemoryGraphicsProtocol {
    
    /// Calculate buffer index of coordinates
    /// - Parameters:
    ///   - x: X coordinate
    ///   - y: Y coordinate
    /// - Returns: Buffer index or -1 on error
    @inline(__always)
    func getIndex(_ x: Int, _ y: Int) -> Int {
        guard !clipped(x, y) else { return -1 }
        return y * bytesPerLine + x * indexSize
    }
    
    /// Calculate buffer index of point
    /// - Parameter point: Point
    /// - Returns: Buffer index or -1 on error
    @inline(__always)
    func getIndex(_ point: IPoint) -> Int {
        return getIndex(point.x, point.y)
    }
    
    /// Calculate buffer index for start of row
    /// - Parameter y: Row number
    /// - Returns: Buffer index or -1 on error
    @inline(__always)
    func getRowIndex(_ y: Int) -> Int {
        return getIndex(0, y)
    }
    
}
