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

class CGGraphics {
    
    /// Size considering oversampling factor
    var size: ISize
    
    /// Frame size
    var frameSize: ISize
    
    /// Oversampling factor
    var oversampling: Int
    
    /// Current drawing position
    var p: IPoint = .zero

    /// Drawing color
    var color: RGBAColor = .white
    
    var context: CGContext?
    var blendMode: CGBlendMode = .normal
    
    var cgImage: CGImage? {
        context != nil ? context!.makeImage() : nil
    }
    
    init(frameSize: CGSize, oversampling: Int = 1) {
        self.oversampling = max(min(oversampling, 3), 1)
        self.frameSize    = ISize(size: frameSize)
        self.size         = ISize(width: Int(frameSize.width) * self.oversampling, height: Int(frameSize.height) * self.oversampling)

        self.context = CGContext(
            data: nil,
            width: self.size.width, height: self.size.height,
            bitsPerComponent: 8,
            bytesPerRow: (((self.size.width * 4) + 15) / 16) * 16,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
    }

    /// Set blending mode
    func setBlendMode(_ mode: CGBlendMode) -> CGBlendMode {
        let currentBlendMode = blendMode
        if let ctx = context {
            ctx.setBlendMode(mode)
            blendMode = mode
        }
        return currentBlendMode
    }

    func move(to: IPoint) {
        self.p = to
    }
    
    func setPixel(_ x: Int, _ y: Int, color: RGBAColor?) {
        if let ctx = context {
            ctx.setStrokeColor(color?.cgColor ?? self.color.cgColor)
            ctx.setLineWidth(1)
            ctx.move(to: CGPoint(x: x, y: y))
            ctx.addLine(to: CGPoint(x: x, y: y))
            ctx.strokePath()
        }
    }
    
    /// Draw a line
    func drawLine(from: IPoint, to: IPoint, color: RGBAColor? = nil) {
        if let ctx = context {
            ctx.setStrokeColor(color?.cgColor ?? self.color.cgColor)
            ctx.setLineWidth(1)
            ctx.move(to: from.cgPoint)
            ctx.addLine(to: to.cgPoint)
            ctx.strokePath()
        }
    }
    
    func drawHLine(from: IPoint, to: Int, color: RGBAColor? = nil) {
        if let ctx = context {
            ctx.setStrokeColor(color?.cgColor ?? self.color.cgColor)
            ctx.setLineWidth(1)
            ctx.move(to: from.cgPoint)
            ctx.addLine(to: CGPoint(x: to, y: from.y))
            ctx.strokePath()
        }
    }
    
    func drawVLine(from: IPoint, to: Int, color: RGBAColor? = nil) {
        if let ctx = context {
            ctx.setStrokeColor(color?.cgColor ?? self.color.cgColor)
            ctx.setLineWidth(1)
            ctx.move(to: from.cgPoint)
            ctx.addLine(to: CGPoint(x: from.x, y: to))
            ctx.strokePath()
        }
    }
        
    /// Draw a rectangle
    func drawRect(from: IPoint, to: IPoint, color: RGBAColor? = nil) {
        if let ctx = context {
            ctx.setStrokeColor(color?.cgColor ?? self.color.cgColor)
            ctx.setLineWidth(1)
            ctx.addRect(CGRect(origin: from.cgPoint, size: CGSize(width: to.x - from.x, height: to.y - from.y)))
            ctx.strokePath()
        }
    }

    /// Draw a filled rectangle
    func drawRectFill(from: IPoint, to: IPoint, color: RGBAColor? = nil) {
        if let ctx = context {
            ctx.setStrokeColor(color?.cgColor ?? self.color.cgColor)
            ctx.setFillColor(color?.cgColor ?? self.color.cgColor)
            ctx.setLineWidth(1)
            ctx.addRect(CGRect(origin: from.cgPoint, size: CGSize(width: to.x - from.x, height: to.y - from.y)))
            ctx.fillPath()
        }
    }
    

    
}
