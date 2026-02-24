//
//  ImageGraphics.swift
//  SwiFractal
//
//  Created by Dirk Braner on 23.02.26.
//

import SwiftUI
import Accelerate

// ------------------------------------------------------------------
//  Class ImageGraphics
//
//  Class for drawing into vImage buffer
// ------------------------------------------------------------------

class ImageGraphics : Graphics {
    var rowBytes: Int = 0
    var imagePtr: ImagePtr? = nil
    var image: VImage? = nil
    
    /// Initialize ImageGraphics object
    override init(_ size: CGSize, oversampling: Int = 1) {
        super.init(size, oversampling: oversampling)
        print("oversampling: \(oversampling), width: \(width), height: \(height), frameSize: \(frameSize)")
        
        // Create buffer
        image = vImage.PixelBuffer<vImage.Interleaved8x4>(width: width, height: height)
        rowBytes = image!.rowStride * image!.channelCount
        
        // Initialize buffer with black color
        image!.withUnsafeMutableBufferPointer { imagePtr in
            initBuffer(imagePtr)
        }
    }
    
    /// Initialize ImageGraphics object with pixel channel buffer
    init(_ pixels: [Pixel_8], _ size: CGSize) {
        guard pixels.count == Int(size.width) * Int(size.height) else {
            fatalError("Invalid pixel count in ImageGraphics.init(). Expected \(Int(size.width) * Int(size.height)), got \(pixels.count).")
        }

        super.init(size)

        // Create buffer
        image = vImage.PixelBuffer<vImage.Interleaved8x4>(pixelValues: pixels, size: vImage.Size(width: Int(size.width), height: Int(size.height)))
        rowBytes = image!.rowStride * image!.channelCount
    }
   
    /// Calculate buffer index from coordinates
    func getBufferIndex(_ x: Int, _ y: Int) -> Int {
        return y * rowBytes + x * image!.channelCount
    }
    
    /// Calculate buffer index from point
    func getBufferIndex(_ point: CGPoint) -> Int {
        return Int(point.y) * rowBytes + Int(point.x) * image!.channelCount
    }
    
    /// Initialize graphics buffer with color
    func initBuffer(_ imagePtr: ImagePtr, _ color: RGBAColor = .black) {
        for y in 0..<height {
            var i = y * rowBytes
            for _ in 0..<width {
                imagePtr[i]     = color.redi
                imagePtr[i + 1] = color.greeni
                imagePtr[i + 2] = color.bluei
                imagePtr[i + 3] = color.alphai
                i += image!.byteCountPerPixel
            }
        }
    }
    
    // Alternative for creating and freeing an image buffer
    // See https://stackoverflow.com/questions/73199980/how-do-i-use-vimage-buffer-to-manage-pixels-and-create-an-image
    /*
    func beginDraw(_ width: Int, _ height: Int) -> Bool {
        var b = try! vImage_Buffer(width: 100, height: 100, bitsPerPixel: 24)
        var bptr = b.data.assumingMemoryBound(to: Pixel_8.self)
        
        return true
    }
     
    func endDraw() {
     if b != nil {b.free }
    }
    */
    
    /// Initialize image pointer. This function must be called before
    /// the first drawing function!
    override func beginDraw(drawAction: () -> Void) async -> Bool {
        if super.beginDraw() {
            image!.withUnsafeMutableBufferPointer { imagePtr in
                self.imagePtr = imagePtr
                drawAction()
                self.imagePtr = nil
            }

            return true
        }
        
        return false
    }

    /// Clear graphics
    override func clear(color: RGBAColor? = nil) {
        // guard isDrawing && imagePtr != nil else { return }

        let c = color ?? self.color
        image?.withUnsafePointerToVImageBuffer { iptr in
            _ = vImageBufferFill_ARGB8888(iptr, c.pixel, vImage_Flags(kvImageNoFlags))
        }
    }
    
    /// Set a pixel
    override func setPixel(_ x: Int, _ y: Int, color: RGBAColor? = nil) {
        guard isDrawing else { return }

        let c = color ?? self.color
        let index = getBufferIndex(x, y)

        imagePtr![index]     = c.redi
        imagePtr![index + 1] = c.greeni
        imagePtr![index + 2] = c.bluei
        imagePtr![index + 3] = c.alphai
    }
    
    /// Draw a horizontal line without updating drawing position
    override func drawHLine(_ from: CGPoint, _ to: Int, color: RGBAColor? = nil) -> CGPoint {
        guard isDrawing else { return from }

        let c = color ?? self.color
        let index1 = getBufferIndex(from)
        let index2 = getBufferIndex(to, Int(from.y))
       
        for i in stride(from: index1, to: index2, by: image!.channelCount) {
            imagePtr![i]     = c.redi
            imagePtr![i + 1] = c.greeni
            imagePtr![i + 2] = c.bluei
            imagePtr![i + 3] = c.alphai
        }
        
        return CGPoint(x: to, y: Int(from.y))
    }
    
    /// Draw a vertical line without updating drawing position
    override func drawVLine(_ from: CGPoint, _ to: Int, color: RGBAColor? = nil) -> CGPoint {
        guard isDrawing else { return from }

        let c = color ?? self.color
        let index1 = getBufferIndex(from)
        let index2 = getBufferIndex(Int(from.x), to)

        for i in stride(from: index1, to: index2, by: rowBytes) {
            imagePtr![i]     = c.redi
            imagePtr![i + 1] = c.greeni
            imagePtr![i + 2] = c.bluei
            imagePtr![i + 3] = c.alphai
        }
        
        return CGPoint(x: Int(from.x), y: to)
    }

    /// Draw a filled rectangle
    override func drawRectFill(_ x1: Int, _ y1: Int, _ x2: Int, _ y2: Int, color: RGBAColor? = nil) {
        guard isDrawing else { return }

        let c = color ?? self.color
        var index1 = getBufferIndex(x1, y)
        let index2 = getBufferIndex(x2, y)

        for _ in y1..<y2 {
            for i in stride(from: index1, to: index2, by: image!.channelCount) {
                imagePtr![i]     = c.redi
                imagePtr![i + 1] = c.greeni
                imagePtr![i + 2] = c.bluei
                imagePtr![i + 3] = c.alphai
            }
            index1 += rowBytes
        }
    }

    /// Initialize graphics from RGBA buffer
    override func initFromColorArray(_ colors: UnsafeBufferPointer<RGBA>) {
        guard isDrawing else { return }
        
        var imageIndex: Int = 0
        var arrayIndex: Int = 0
        
        for _ in 0..<height {
            var lineIndex = imageIndex
            
            for _ in 0..<width {
                imagePtr![lineIndex]     = colors[arrayIndex].redi
                imagePtr![lineIndex + 1] = colors[arrayIndex].greeni
                imagePtr![lineIndex + 2] = colors[arrayIndex].bluei
                imagePtr![lineIndex + 3] = colors[arrayIndex].alphai
                lineIndex += image!.channelCount
                arrayIndex += 1
            }

            imageIndex += rowBytes
        }
    }
    
    /// Convert image buffer to CGImage
    override func updateCGImage() {
        let format = vImage_CGImageFormat(bitsPerComponent: 8, bitsPerPixel: 32, colorSpace: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue))!
        cgImage = image?.makeCGImage(cgImageFormat: format)
    }
    
}


