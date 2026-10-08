//
//  PrGraphics.swift
//
//  Protocol of drawing functions
//
//  Part of SwiFractal
//
//  Created by Dirk Braner on 16.11.24.
//

import Foundation
import SwiftUI


///
/// Protocol for graphic output
///
protocol GraphicsProtocol {
    
    /// Image as CGImage
    var cgImage: CGImage? { get }
    
    /// Size with oversampling
    var size: ISize { get set }
    
    /// Width with oversampling
    var width: Int { get }
    
    /// Height with oversampling
    var height: Int { get }
    
    /// Output frame size without oversampling
    var frameSize: ISize { get set }
    
    /// Number of bytes per pixel
    var indexSize: Int { get set }
    
    /// Flip on Y-axis
    var flip: Bool { get set }
    
    /// Current drawing position as integer coordinates
    var pos: IPoint { get set }

    /// Drawing color
    var color: RGBAColor { get set }
    
    /// Initialize and perform drawing. Return CGImage
    func beginDraw(drawAction: () -> CGImage?) -> CGImage?
    
    /// Clip coordinates
    func clip(_ x: Int, _ y: Int) -> IPoint
    
    /// Clip point
    func clip(_ point: IPoint) -> IPoint
    
    /// Check if coordinates are clipped
    func clipped(_ x: Int, _ y: Int) -> Bool
    
    /// Check if point is clipped
    func clipped(_ point: IPoint) -> Bool
    
    /// Set drawing position to point
    func move(to point: IPoint)
    
    /// Draw pixel with clipping
    func setPixel(_ x: Int, _ y: Int, color: RGBAColor?)
    
    /// Draw a horizontal line from current position to position x-1 and set drawing position to x, y
    func drawHLine(from: IPoint, to x: Int, color: RGBAColor?)
    
    /// Draw a vertical line from current position to position y-1 and ser drawing position to x, y
    func drawVLine(from: IPoint, to y: Int, color: RGBAColor?)
    
    /// Draw a rectangle
    func drawRect(_ rect: IRect, color: RGBAColor?)

}

//
// Implement basic graphic functions
//
extension GraphicsProtocol {
    
    /// Return oversampling width
    var width: Int { size.width }
    
    /// Return oversampling height
    var height: Int { size.height }
    
    /// Check if coordinates are clipped
    /// - Parameters:
    ///   - x: X coordinate
    ///   - y: Y coordinate
    /// - Returns: true if coordinates are outside of view
    @inline(__always) func clipped(_ x: Int, _ y: Int) -> Bool {
        return x < 0 || x >= width || y < 0 || y >= height
    }
    
    /// Check if point is clipped
    /// - Parameter point: Point
    /// - Returns: true if point is outside of view
    @inline(__always) func clipped(_ point: IPoint) -> Bool {
        return clipped(point.x, point.y)
    }
    
    /// Clip coordinates
    /// - Parameters:
    ///   - x: X coordinate
    ///   - y: Y coordinate
    /// - Returns: Clipped point
    @inline(__always) func clip(_ x: Int, _ y: Int) -> IPoint {
        return IPoint(x: x.clamped(to: 0...width-1), y: y.clamped(to: 0...height-1))
    }
    
    /// Clip point
    /// - Parameter point: Point
    /// - Returns: Clipped point
    @inline(__always) func clip(_ point: IPoint) -> IPoint {
        return clip(point.x, point.y)
    }

}



