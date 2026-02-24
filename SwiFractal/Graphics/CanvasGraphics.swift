//
//  GraphicsCanvas.swift
//  SwiFractal
//
//  Created by Dirk Braner on 23.02.26.
//

import SwiftUI

// ------------------------------------------------------------------
//  Class CanvasGraphics
//
//  Class for drawing into Swift UI graphics context
// ------------------------------------------------------------------

class CanvasGraphics : Graphics {
    var context: GraphicsContext
    
    init(_ context: GraphicsContext, _ size: CGSize) {
        self.context = context
        super.init(size)
    }
    
    /// Set blending mode and return previous blending mode
    func setBlendMode(_ blendMode: GraphicsContext.BlendMode) -> GraphicsContext.BlendMode {
        let currentBlendMode = context.blendMode
        context.blendMode = blendMode
        return currentBlendMode
    }
    
    /// Draw a line withoud modifying drawing position
    override func drawLine(_ from: CGPoint, _ to: CGPoint, color: RGBAColor? = nil) -> CGPoint {
        let c = color == nil ? self.color.shadingColor : GraphicsContext.Shading.color(color!.color)
        self.context.stroke(
            Path() { path in
                path.move(to: from)
                path.addLine(to: to)
            },
            with: c,
            lineWidth: 1
        )
        return to
    }
    
    /// Draw a rectangle
    override func drawRect(_ rect: CGRect, color: RGBAColor? = nil) {
        let c = color == nil ? self.color.shadingColor : GraphicsContext.Shading.color(color!.color)
        self.context.stroke(
            Path() { path in
                path.addRect(rect)
            },
            with: c,
            lineWidth: 1
        )
    }
    
    /// Draw a rectangle
    override func drawRect(_ x1: Int, _ y1: Int, _ x2: Int, _ y2: Int, color: RGBAColor? = nil) {
        let c = color == nil ? self.color.shadingColor : GraphicsContext.Shading.color(color!.color)
        self.context.stroke(
            Path() { path in
                path.addRect(CGRect(x: x1, y: y1, width: x2 - x1, height: y2 - y1))
            },
            with: c,
            lineWidth: 1
        )
    }
    
    /// Draw a filled rectangle
    override func drawRectFill(_ x1: Int, _ y1: Int, _ x2: Int, _ y2: Int, color: RGBAColor? = nil) {
        let c = color == nil ? self.color.shadingColor : GraphicsContext.Shading.color(color!.color)
        self.context.fill(
            Path() { path in
                path.addRect(CGRect(x: x1, y: y1, width: x2 - x1, height: y2 - y1))
            },
            with: c
        )
    }
    
    /// Create CGImage from context
    override func updateCGImage() {
        context.withCGContext { context in
            cgImage = context.makeImage()
        }
    }
}
