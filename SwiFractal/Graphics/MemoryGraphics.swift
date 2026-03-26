//
//  MemoryGraphics.swift
//  SwiFractal
//
//  Created by Dirk Braner on 26.03.26.
//

import SwiftUI

// ------------------------------------------------------------------
//  Class MemoryGraphics
//
//  Class for drawing into UInt32 buffer
// ------------------------------------------------------------------

class MemoryGraphics : Graphics {
    
    var mSize: Int = 0                  // Expected size of array (element count)
    var mImage: [UInt32] = []           // The image array
    
    /// Initialize ImageGraphics object
    override init(_ size: CGSize, oversampling: Int = 1) {
        super.init(size, oversampling: oversampling)
        
        // Expected size of array mImage
        self.mSize = width * height
        
        // Create the image array
        self.mImage = Array(repeating: 0, count: mSize)
    }
   
    /// Calculate buffer index from coordinates. Coordinates are clipped to 0..width-1, 0..height-1
    func getBufferIndex(_ x: Int, _ y: Int) -> Int {
        let xx = min(max(x, 0), width - 1)
        let yy = min(max(y, 0), height - 1)
        return yy * width + xx
    }
    
    /// Calculate buffer index from point
    func getBufferIndex(_ point: CGPoint) -> Int {
        return getBufferIndex(Int(point.x), Int(point.y))
    }
    
    /// Get color as UInt32
    func getColor(_ color: RGBAColor? = nil) -> UInt32 {
        return (color ?? self.color).rgbi32
    }
    
    /// Clear graphics
    override func clear(color: RGBAColor? = nil) {
        guard isDrawing else { return }

        mImage.withUnsafeMutableBufferPointer { ptr in
            ptr.initialize(repeating: getColor(color))
        }
    }
    
    /// Set a pixel
    override func setPixel(_ x: Int, _ y: Int, color: RGBAColor? = nil) {
        guard isDrawing else { return }

        let index = getBufferIndex(x, y)
        mImage[index] = getColor(color)
    }
    
    /// Draw a horizontal line without updating drawing position
    override func drawHLine(_ from: CGPoint, _ to: Int, color: RGBAColor? = nil) -> CGPoint {
        guard isDrawing else { return from }

        let c = getColor(color)
        let index1 = getBufferIndex(from)
        let index2 = getBufferIndex(to, Int(from.y))
       
        for i in stride(from: index1, to: index2, by: 1) {
            mImage[i] = c
        }
        
        return CGPoint(x: to, y: Int(from.y))
    }
    
    /// Draw a vertical line without updating drawing position
    override func drawVLine(_ from: CGPoint, _ to: Int, color: RGBAColor? = nil) -> CGPoint {
        guard isDrawing else { return from }

        let c = getColor(color)
        let index1 = getBufferIndex(from)
        let index2 = getBufferIndex(Int(from.x), to)

        for i in stride(from: index1, to: index2, by: width) {
            mImage[i] = c
        }
        
        return CGPoint(x: Int(from.x), y: to)
    }

    /// Draw a filled rectangle
    override func drawRectFill(_ x1: Int, _ y1: Int, _ x2: Int, _ y2: Int, color: RGBAColor? = nil) {
        guard isDrawing else { return }

        let c = getColor(color)
        var index1 = getBufferIndex(x1, y)
        let index2 = getBufferIndex(x2, y)

        for _ in y1..<y2 {
            for i in stride(from: index1, to: index2, by: 1) {
                mImage[i] = c
            }
            index1 += width
        }
    }
    
    /// Convert image buffer to CGImage
    override func updateCGImage() {
        guard mImage.count == mSize else { return }
        
        let bitsPerComponent = 8
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        // Wir nutzen .premultipliedLast oder .last für RGBA
        let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue

        // 3. Context erstellen und Daten kopieren
        // Wir nutzen eine Kopie der Daten, um Speicher-Crashes zu vermeiden
        var data = mImage
        guard let context = CGContext(
            data: &data,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else { return }

        // 4. Das finale Bild generieren
        cgImage = context.makeImage()
    }
    
}


