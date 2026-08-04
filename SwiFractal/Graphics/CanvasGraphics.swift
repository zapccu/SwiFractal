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

class CanvasGraphics {
    var context: GraphicsContext
    var size: CGSize
    
    var width: Int { Int(size.width) }
    var height: Int { Int(size.height) }
    
    init(context: GraphicsContext, size: CGSize) {
        self.context = context
        self.size = size
    }
    
    /// Set blending mode and return previous blending mode
    func setBlendMode(_ blendMode: GraphicsContext.BlendMode) -> GraphicsContext.BlendMode {
        let currentBlendMode = context.blendMode
        self.context.blendMode = blendMode
        return currentBlendMode
    }
    
    /// Draw a line withoud modifying drawing position
    func drawLine(from: IPoint, to: IPoint, color: RGBAColor) {
        let c = GraphicsContext.Shading.color(color.color)
        self.context.stroke(
            Path() { path in
                path.move(to: from.cgPoint)
                path.addLine(to: to.cgPoint)
            },
            with: c,
            lineWidth: 1
        )
    }
    
    /// Draw a rectangle
    func drawRect(rect: IRect, color: RGBAColor) {
        let c = GraphicsContext.Shading.color(color.color)
        self.context.stroke(
            Path() { path in
                path.addRect(rect.cgRect)
            },
            with: c,
            lineWidth: 1
        )
    }
    
    /// Draw a rectangle
    func drawRect(from: IPoint, to: IPoint, color: RGBAColor) {
        let c = GraphicsContext.Shading.color(color.color)
        self.context.stroke(
            Path() { path in
                path.addRect(CGRect(x: from.x, y: from.y, width: to.x-from.x, height: to.y-from.y))
            },
            with: c,
            lineWidth: 1
        )
    }
    
    /// Draw a filled rectangle
    func drawRectFill(from: IPoint, to: IPoint, color: RGBAColor) {
        let c = GraphicsContext.Shading.color(color.color)
        self.context.fill(
            Path() { path in
                path.addRect(CGRect(x: from.x, y: from.y, width: to.x-from.x, height: to.y-from.y))
            },
            with: c
        )
    }
    
    /// Scale image to destination frame size and draw image into a graphics context
    func drawImage(cgImage: CGImage?) {
        if let suiImage = cgImage?.suiImage {
            var imageContext = self.context
            
            imageContext.translateBy(x: 0, y: size.height)
            imageContext.scaleBy(x: 1.0, y: -1.0)
            imageContext.draw(suiImage, in: CGRect(origin: .zero, size: size))
        }
        else {
            debugPrint("No cgImage / cannot convert cgImage to suiImage")
        }
    }

}
