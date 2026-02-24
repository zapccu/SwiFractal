//
//  CGGraphics.swift
//  SwiFractal
//
//  Created by Dirk Braner on 23.02.26.
//

import SwiftUI

// ------------------------------------------------------------------
//  Class CGGraphics
//
//  Class for drawing into Core Graphics context
// ------------------------------------------------------------------

class CGGraphics : Graphics {
    var context: CGContext?
    var blendMode: CGBlendMode = .normal

    override init(_ size: CGSize, oversampling: Int = 1) {
        super.init(size, oversampling: oversampling)
        context = CGContext(
            data: nil,
            width: width, height: height,
            bitsPerComponent: 8,
            bytesPerRow: (((width * 4) + 15) / 16) * 16,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
    }
    
    init(_ context: CGContext, oversampling: Int = 1) {
        super.init(CGSize(width: context.width, height: context.height), oversampling: oversampling)
        self.context = context
    }

    func setBlendMode(_ mode: CGBlendMode) -> CGBlendMode {
        let currentBlendMode = blendMode
        context!.setBlendMode(mode)
        blendMode = mode
        return currentBlendMode
    }
    
    /// Being drawing, execute drawing closure
    override func beginDraw(drawAction: () -> Void) async -> Bool {
        if super.beginDraw() && context != nil {
            drawAction()
            return true
        }
        
        return false
    }
    
    /// Set drawing color
    override func setColor(_ color: RGBAColor) {
        super.setColor(color)
        if let c = context {
            c.setStrokeColor(color.cgColor)
        }
    }

    /// Draw a line
    override func drawLine(_ from: CGPoint, _ to: CGPoint, color: RGBAColor? = nil) -> CGPoint {
        if let c = context {
            c.setStrokeColor(color?.cgColor ?? self.color.cgColor)
            c.setLineWidth(1)
            c.move(to: from)
            c.addLine(to: to)
            c.strokePath()
        }
        return to
    }
        
    /// Draw a rectangle
    override func drawRect(_ x1: Int, _ y1: Int, _ x2: Int, _ y2: Int, color: RGBAColor? = nil) {
        if let c = context {
            c.setStrokeColor(color?.cgColor ?? self.color.cgColor)
            c.setLineWidth(1)
            c.addRect(CGRect(x: x1, y: y1, width: x2-x1, height: y2-y1))
            c.strokePath()
        }
    }

    /// Draw a filled rectangle
    override func drawRectFill(_ x1: Int, _ y1: Int, _ x2: Int, _ y2: Int, color: RGBAColor? = nil) {
        if let c = context {
            c.setStrokeColor(color?.cgColor ?? self.color.cgColor)
            c.setFillColor(color?.cgColor ?? self.color.cgColor)
            c.setLineWidth(1)
            c.addRect(CGRect(x: x1, y: y1, width: x2-x1, height: y2-y1))
            c.fillPath()
        }
    }
    
    /// Create CGImage from context or return existing CGImage
    override func updateCGImage() {
        if context != nil {
            cgImage = context!.makeImage()
        }
    }
    
}
