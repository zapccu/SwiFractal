//
//  Graphics.swift
//
//  Implementation of drawing functions
//
//  Part of SwiFractal
//
//  Created by Dirk Braner on 16.11.24.
//

import SwiftUI

//
// Protocol for graphic output
//
protocol Graphics {
    
    /// Return image as CGImage
    var cgImage: CGImage? { get }
    
    /// Size considering oversampling factor
    var size: ISize { get set }
    
    /// Return output frame size without oversampling
    var frameSize: ISize { get set }
    
    /// Return number of bytes per line
    var bytesPerLine: Int { get }
    
    var indexSize: Int { get }
    
    /// Current drawing position
    var p: IPoint { get set }

    /// Drawing color
    var color: RGBAColor { get set }
    
    /// Initialize drawing
    func beginDraw(drawAction: () -> CGImage?) -> CGImage?
    
    /// Set drawing position to specified point
    func move(to: IPoint)
    
    /// Draw pixel
    func setPixel(_ x: Int, _ y: Int, color: RGBAColor?)
    
    /// Draw a horizontal line to position x-1 without modifiying drawing position
    func drawHLine(from: IPoint, to x: Int, color: RGBAColor?)

    /// Draw a vertical line to position y-1 without modifiying drawing position
    func drawVLine(from: IPoint, to y: Int, color: RGBAColor?)

    /// Draw a filled rectangle including point to
    func drawRectFill(from: IPoint, to: IPoint, color: RGBAColor?)

}

