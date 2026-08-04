//
//  GraphicsExt.swift
//  SwiFractal
//
//  Created by Dirk Braner on 06.01.25.
//

import SwiftUI
import Accelerate

typealias VImage = vImage.PixelBuffer<vImage.Interleaved8x4>
typealias ImagePtr = UnsafeMutableBufferPointer<vImage.Interleaved8x4.ComponentType>

extension Graphics {
    
    /// Return oversampling width as Int
    var width: Int { Int(size.width) }
    
    /// Return oversampling height as Int
    var height: Int { Int(size.height) }
    
    /// Return X coordinate of current drawing position
    var x: Int { p.x }

    /// Return Y coordinate of current drawing position
    var y: Int { p.y }
    
    /// Rreturn current drawing position as CGPoint
    var cgPoint: CGPoint { p.cgPoint }

    /// Calculate buffer index from coordinates
    /// Return -1 if coordinates are clipped
    func getBufferIndex(_ x: Int, _ y: Int, clip: Bool = true) -> Int {
        guard !clip || (x >= 0 && y >= 0 && x < width && y < height) else { return -1 }
        return y * bytesPerLine + x * indexSize
    }
    
    /// Calculate buffer index from point
    func getBufferIndex(_ point: IPoint, clip: Bool = true) -> Int {
        return getBufferIndex(point.x, point.y, clip: clip)
    }
    
    /// Draw a horizontal line from current drawing position to coordinate x-1 and set drawing position to x
    func drawHLine(to x: Int, color: RGBAColor? = nil) -> IPoint {
        self.drawHLine(from: p, to: x, color: color)
        self.move(to: IPoint(x: x, y: p.y))
        return self.p
    }

    /// Draw a vertical line from drawing position to Y coordinate and update drawing position
    func drawVLine(to y: Int, color: RGBAColor? = nil) -> IPoint {
        self.drawVLine(from: p, to: y, color: color)
        self.move(to: IPoint(x: p.x, y: y))
        return self.p
    }
    
    // Draw a rectangle
    func drawRect(rect: IRect, color: RGBAColor? = nil) {
        // Override this function in child classes for better performance
        self.drawRect(from: rect.origin, to: rect.destination, color: color)
    }
    
    /// Draw a rectangle
    func drawRect(from: IPoint, to: IPoint, color: RGBAColor? = nil) {
        // Override this function in child classes for better performance
        
        for x in from.x...to.x {
            self.setPixel(x, from.y, color: color)
            self.setPixel(x, to.y, color: color)
        }

        for y in from.y+1..<to.y {
            self.setPixel(from.x, y, color: color)
            self.setPixel(to.x, y, color: color)
        }
    }
    
    /// Init view from RGBAColor array
    func initFromColorArray(colors: UnsafeBufferPointer<RGBA>) {
        for y in 0..<height {
            for x in 0..<width {
                let offset = y * width + x
                if offset >= colors.count { return }
                self.setPixel(x, y, color: RGBAColor(colors[offset]))
            }
        }
    }

}



