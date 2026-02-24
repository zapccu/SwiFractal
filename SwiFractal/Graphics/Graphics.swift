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

// ------------------------------------------------------------------
//  Protocol Graphics
//
//  Implementation of drawing functions.
//  Override functions in derived classes if necessary.
// ------------------------------------------------------------------

class Graphics {
    // Resulting image, created/updated by function endDraw()
    var cgImage: CGImage? = nil
    
    // Dimensions of drawing area
    var size: CGSize                        // Oversampling size
    var frameSize: CGSize                   // Size of the surrounding frame
    var width: Int { Int(size.width) }      // Return oversampling width as integer
    var height: Int { Int(size.height) }    // Return oversampling height as integer
    
    // Oversampling
    let oversampling: Int                   // Oversampling factor 1 = no oversampling
    
    // Current drawing position
    var p = CGPoint()
    var x: Int { Int(p.x) }
    var y: Int { Int(p.y) }
    
    // Current drawing color
    var color: RGBAColor = .black
        
    // Flag for drawing in progress
    var isDrawing: Bool = false

    /// Construct graphics object
    init(_ size: CGSize, oversampling: Int = 1) {
        self.oversampling = max(min(oversampling, 3), 1)
        self.frameSize    = size
        self.size         = CGSize(width: size.width * Double(self.oversampling), height: size.height * Double(self.oversampling))
    }

    /// Clear graphics, fill with color
    func clear(color: RGBAColor? = nil) {
        drawRectFill(0, 0, width, height, color: color)
    }
    
    /// Set drawing color
    func setColor(_ color: RGBAColor) {
        self.color = color
    }
        
    /// Start drawing
    func beginDraw() -> Bool {
        isDrawing = true
        cgImage = nil
        return true
    }
    
    /// Start drawing and call the draw action
    func beginDraw(drawAction: () -> Void) async -> Bool {
        if beginDraw() {
            drawAction()
            return true
        }
        
        return false
    }
    
    /// End drawing
    func endDraw() {
        updateCGImage()
        isDrawing = false
    }
    
    /// Move drawing position to specified coordinates
    func moveTo(_ x: Int, _ y: Int) {
        self.p = CGPoint(x: Double(x), y: Double(y))
    }
    
    /// Move drawing position to specified point
    func moveTo(_ p: CGPoint) {
        self.p = p
    }
    
    /// Set pixel to color without modifiying drawing position
    func setPixel(_ x: Int, _ y: Int, color: RGBAColor? = nil) {
        // Override this function in child classes for better performance
        _ = drawLine(p, CGPoint(x: x+1, y: y), color: color)
    }
    
    /// Draw a line without modifiying drawing position
    func drawLine(_ from: CGPoint, _ to: CGPoint, color: RGBAColor? = nil) -> CGPoint {
        // All default drawing functions are using this function
        // This function must(!) be overridden in child classes
        return to
    }
    
    /// Draw a line from drawing position to point and update drawing position
    func drawLineTo(_ to: CGPoint, color: RGBAColor? = nil) -> CGPoint {
        let p = drawLine(p, to, color: color)
        moveTo(to)
        return p
    }
    
    /// Draw a horizontal line without modifiying drawing position
    func drawHLine(_ from: CGPoint, _ to: Int, color: RGBAColor? = nil) -> CGPoint {
        return drawLine(from, CGPoint(x: to, y: Int(from.y)), color: color)
    }

    /// Draw a horizontal line from drawing position to X coordinate and update drawing position
    func drawHLineTo(_ x: Int, color: RGBAColor? = nil) -> CGPoint {
        return drawLineTo(CGPoint(x: x, y: self.y), color: color)
    }

    /// Draw a vertical line without modifiying drawing position
    func drawVLine(_ from: CGPoint, _ to: Int, color: RGBAColor? = nil) -> CGPoint {
        return drawLine(from, CGPoint(x: Int(from.x), y: to), color: color)
    }

    /// Draw a vertical line from drawing position to Y coordinate and update drawing position
    func drawVLineTo(_ y: Int, color: RGBAColor? = nil) -> CGPoint {
        return drawLineTo(CGPoint(x: self.x, y: y), color: color)
    }
    
    // Draw a rectangle
    func drawRect(_ rect: CGRect, color: RGBAColor? = nil) {
        // Override this function in child classes for better performance
        drawRect(Int(rect.origin.x), Int(rect.origin.y), Int(rect.maxX), Int(rect.maxY), color: color)
    }
    
    /// Draw a rectangle
    func drawRect(_ x1: Int, _ y1: Int, _ x2: Int, _ y2: Int, color: RGBAColor? = nil) {
        // Override this function in child classes for better performance
        _ = drawLine(CGPoint(x: x1, y: y1), CGPoint(x: x2, y: y1), color: color)
        _ = drawLine(CGPoint(x: x2, y: y1), CGPoint(x: x2, y: y2), color: color)
        _ = drawLine(CGPoint(x: x2, y: y2), CGPoint(x: x1, y: y2), color: color)
        _ = drawLine(CGPoint(x: x1, y: y2), CGPoint(x: x1, y: y1), color: color)
    }
    
    /// Draw a filled rectangle
    func drawRectFill(_ x1: Int, _ y1: Int, _ x2: Int, _ y2: Int, color: RGBAColor? = nil) {
        // Override this function in child classes for better performance
        for y in y1...y2 {
            _ = drawLine(CGPoint(x: x1, y: y), CGPoint(x: x2, y: y), color: color)
        }
    }

    /// Init view from RGBAColor array
    func initFromColorArray(_ colors: UnsafeBufferPointer<RGBA>) {
        guard isDrawing else { return }
        
        for y in 0..<height {
            for x in 0..<width {
                let offset = y * width + x
                if offset >= colors.count { return }
                setPixel(x, y, color: RGBAColor(colors[offset]))
            }
        }
    }
    
    /// Create a CGImage from Graphics object
    /// This function is called from endDraw()
    /// This funct must(!) be overriden in child classes to create a valid cgImage
    func updateCGImage() {
        cgImage = nil
    }
    
    /// Return cgImage
    func getCGImage() -> CGImage? {
        // Override this function in child classes if needed
        return cgImage
    }
    
    /// Scale image to destination frame size and draw image into a graphics context
    func drawImage(_ context: GraphicsContext) {
        if cgImage != nil {
            // let nsImage = NSImage(cgImage: cgImage!, size: size)
            // let img = Image(nsImage: nsImage).resizable().interpolation(.high) //.frame(width: frameSize.width, height: frameSize.height, alignment: .topLeading)
            context.draw(Image(decorative: cgImage!, scale: 1.0, orientation: .downMirrored), at: CGPoint(x: 0, y: 0), anchor: .zero)
            // context.draw(img, at: .zero, anchor: .topLeading)
            //context.draw(img, in: CGRect(origin: .zero, size: frameSize))
        }
        else {
            print("No image to draw")
        }
    }

}

