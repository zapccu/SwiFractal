//
//  MemoryGraphics.swift
//  SwiFractal
//
//  Created by Dirk Braner on 26.03.26.
//

import SwiftUI
import Accelerate


// ------------------------------------------------------------------
//  Class MemoryGraphics
//
//  Class for drawing into UInt32 buffer
// ------------------------------------------------------------------

class MemoryGraphics : Graphics {

    /// Size considering oversampling factor
    var size: ISize
    
    /// Frame size
    var frameSize: ISize
    
    var bytesPerLine: Int
    
    var indexSize: Int
    
    /// Oversampling factor
    var oversampling: Int
    
    /// Current drawing position
    var p: IPoint = .zero

    /// Drawing color
    var color: RGBAColor = .white
    
    var cgImage: CGImage? {
        do {
            let cgImageFormat = vImage_CGImageFormat(
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                colorSpace: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.first.rawValue)
            )!
            
            // Source buffer is pointing to mImage
            var source = vImage_Buffer(
                data: mImage.baseAddress!,
                height: vImagePixelCount(width),
                width: vImagePixelCount(height),
                rowBytes: width * MemoryLayout<UInt32>.stride
            )
            
            if oversampling > 1 {
                // Create destination buffer
                var destination = try vImage_Buffer(
                    width: frameSize.width,
                    height: frameSize.height,
                    bitsPerPixel: 32
                )
                defer { destination.free() }
                
                let error = vImageScale_ARGB8888(&source, &destination, nil,
                                                 vImage_Flags(kvImageHighQualityResampling))
                guard error == kvImageNoError else {
                    throw NSError(domain: "vImage", code: Int(error))
                }
                
                return try destination.createCGImage(format: cgImageFormat)
            }
            else {
                return try source.createCGImage(format: cgImageFormat)
            }
        }
        catch {
            return nil
        }
    }
    
    var mSize: Int = 0                                  // Expected size of array (element count)
    var mImage: UnsafeMutableBufferPointer<UInt32>      // The image array
    
    /// Initialize ImageGraphics object
    init(frameSize: CGSize, oversampling: Int = 1) {
        self.oversampling = max(min(oversampling, 3), 1)
        self.frameSize    = ISize(size: frameSize)
        self.size         = ISize(width: Int(frameSize.width) * self.oversampling, height: Int(frameSize.height) * self.oversampling)

        // Entries per line (buffer is a [UInt32])
        self.bytesPerLine = self.size.width
        self.indexSize = 1
        
        // Expected size of array mImage
        self.mSize = self.size.width * self.size.height
        
        // Create the image array
        self.mImage = UnsafeMutableBufferPointer<UInt32>.allocate(capacity: self.mSize)
        
        clear(color: .black)
    }
    
    deinit {
        mImage.deallocate()
    }
    
    func beginDraw(drawAction: () -> CGImage?) -> CGImage? {
        return drawAction()
    }
    
    /// Get color as UInt32
    func getColor(_ color: RGBAColor? = nil) -> UInt32 {
        return (color ?? self.color).argb8888
    }
    
    /// Clear graphics
    func clear(color: RGBAColor? = nil) {
        let color = getColor(color)
        mImage.initialize(repeating: color)
    }
    
    func move(to: IPoint) {
        self.p = to
    }
    
    /// Set a pixel
    func setPixel(_ x: Int, _ y: Int, color: RGBAColor? = nil) {
        let index = getBufferIndex(x, y)
        guard index >= 0 else { return }
        mImage[index] = getColor(color)
    }
    
    /// Draw a horizontal line without updating drawing position excluding 'to'
    func drawHLine(from: IPoint, to: Int, color: RGBAColor? = nil) {
        let c = getColor(color)
        let index1 = getBufferIndex(from)
        guard index1 >= 0 else { return }
        let index2 = getBufferIndex(min(to, width), from.y, clip: false)
       
        for i in index1..<index2 {
            mImage[i] = c
        }
    }
    
    /// Draw a vertical line without updating drawing position excluding 'to'
    func drawVLine(from: IPoint, to: Int, color: RGBAColor? = nil) {
        let c = getColor(color)
        let index1 = getBufferIndex(from)
        guard index1 >= 0 else { return }
        let index2 = getBufferIndex(from.x, min(to, height), clip: false)

        for i in stride(from: index1, to: index2, by: width) {
            mImage[i] = c
        }
    }

    /// Draw a filled rectangle including 'from' and 'to'
    func drawRectFill(from: IPoint, to: IPoint, color: RGBAColor? = nil) {
        let c = getColor(color)
        var index1 = getBufferIndex(from.x, y)
        guard index1 >= 0 else { return }
        var index2 = getBufferIndex(min(to.x+1, width-1), min(y+1, height-1), clip: false)

        for _ in from.y...to.y {
            for i in stride(from: index1, to: index2, by: 1) {
                if i >= mSize { break }
                mImage[i] = c
            }
            index1 += width
            index2 += width
        }
    }

}


