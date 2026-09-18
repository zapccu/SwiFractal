//
//  ImageGraphics.swift
//  SwiFractal
//
//  Created by Dirk Braner on 23.02.26.
//

import SwiftUI
import Accelerate


///
///  Draw into vImage buffer
///
final class ImageGraphics : Graphics {
        
    /// Size considering oversampling factor
    var size: ISize
    
    /// Frame size without oversampling
    var frameSize: ISize
        
    /// Current drawing position
    var p: IPoint = .zero

    /// Drawing color
    var color: RGBAColor = .white
    
    var bytesPerLine: Int = 0               // Bytes per row
    var indexSize: Int                      // Index distance per point
    
    // The vImage
    var image: vImage.PixelBuffer<vImage.Interleaved8x4>
    
    // Pointer for direct read/write. Initialized by beginDraw()
    var ptr: UnsafeMutableRawPointer?
    
    /// Oversampling factor
    var oversampling: Bool { frameSize != size }

    /// Create CGImage from image buffer. nil on error
    var cgImage: CGImage? {

        // Format of CGImage
        let cgImageFormat = vImage_CGImageFormat(
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            colorSpace: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.first.rawValue),
            renderingIntent: .defaultIntent
        )!
        
        // Image with oversampling must be scaled down to frame size
        if oversampling {
            // Create destination buffer
            let destination = vImage.PixelBuffer<vImage.Interleaved8x4>(
                width: frameSize.width,
                height: frameSize.height
            )

            do {
                try image.withUnsafePointerToVImageBuffer { src in
                    try destination.withUnsafePointerToVImageBuffer { dst in
                        // High quality resampling
                        let error = vImageScale_ARGB8888(src, dst, nil,
                            vImage_Flags(kvImageHighQualityResampling))
                        guard error == kvImageNoError else {
                            throw NSError(domain: "vImage", code: Int(error))
                        }
                    }
                }
            }
            catch {
                return nil
            }

            return destination.makeCGImage(cgImageFormat: cgImageFormat)
        }
        else {
            return image.makeCGImage(cgImageFormat: cgImageFormat)
        }
    }
    
    /// Initialize ImageGraphics object
    /// - Parameters:
    ///   - frameSize: Final image size without oversampling
    ///   - size: Image size considering oversampling factor
    init(frameSize: CGSize, size: ISize) {
        self.frameSize = ISize(size: frameSize)
        self.size      = size
        
        // Create image buffer
        self.image = vImage.PixelBuffer<vImage.Interleaved8x4>(width: self.size.width, height: self.size.height)
        
        // Calculate number of bytes per line
        self.bytesPerLine = image.rowStride * image.channelCount
        self.indexSize = image.channelCount
        
        // Initialize buffer with black color
        clear(color: .black)
    }
    
    /// Initialize ImageGraphics object with pixel channel buffer
    /*
    init(pixels: [Pixel_8], frameSize: CGSize, oversampling: Int) {
        guard pixels.count == Int(size.width) * Int(size.height) else {
            fatalError("Invalid pixel count in ImageGraphics.init(). Expected \(Int(size.width) * Int(size.height)), got \(pixels.count).")
        }

        self.oversampling = max(min(oversampling, 3), 1)
        self.frameSize    = ISize(size: frameSize)
        self.size         = ISize(width: Int(size.width * Double(self.oversampling)), height: Int(size.height * Double(self.oversampling)))

        // Create buffer
        image = vImage.PixelBuffer<vImage.Interleaved8x4>(pixelValues: pixels, size: vImage.Size(width: Int(size.width), height: Int(size.height)))
        bytesPerLine = image!.rowStride * image!.channelCount
    }
     */
    
    /// Start drawing. Initialize pointer to image buffer and call drawing action.
    /// - Parameter drawAction: Drawing action (closure)
    /// - Returns: Image
    func beginDraw(drawAction: () -> CGImage?) -> CGImage? {
        return image.withUnsafeMutableBufferPointer { imagePtr in
            self.ptr = UnsafeMutableRawPointer(imagePtr.baseAddress!)
            let cgImage = drawAction()
            self.ptr = nil
            return cgImage
        }
    }
    
    /// Start drawing. Initialize pointer to image buffer and call drawing action.
    /// - Parameter drawAction: Drawing action (closure).
    /// - Returns: Image
    /// - Note: Passing 2 parameters to drawing action: Pointer and size of a pixel in byte.
    func beginDrawParallel(drawAction: (UnsafeMutableRawPointer, Int) -> Void) -> CGImage? {
        return image.withUnsafeMutableBufferPointer { imagePtr in
            let base = UnsafeMutableRawPointer(imagePtr.baseAddress!)
            drawAction(base, indexSize)
            return self.cgImage
        }
    }

    /// Clear graphics
    func clear(color: RGBAColor? = nil) {
        let c: RGBAColor = color ?? .black
        image.withUnsafePointerToVImageBuffer { iptr in
            _ = vImageBufferFill_ARGB8888(iptr, c.pixel, vImage_Flags(kvImageNoFlags))
        }
    }
    
    /// Move position to specified point
    @inline(__always)
    func move(to: IPoint) {
        self.p = to
    }
    
    /// Set a pixel at coordinates
    /// - Parameters:
    ///   - x: X coordinate
    ///   - y: Y coordinate
    ///   - color: Color
    func setPixel(_ x: Int, _ y: Int, color: RGBAColor? = nil) {
        guard let ptr = ptr else { return }
        
        let c = color ?? self.color
        let index = getBufferIndex(x, y)
        guard index >= 0 else { return }
        
        ptr.storeBytes(of: c.argb8888, toByteOffset: index, as: UInt32.self)
    }
    
    /// Set multiple pixels starting from byte offset to the same color
    /// - Parameters:
    ///   - fromByteOffset: Byte offset from buffer start
    ///   - count: Number of pixels
    ///   - color: Color
    ///   - indexSize: Size of a pixel in byte
    /// - Returns: New byte offset
    @inline(__always)
    func setPixels(fromByteOffset: Int, count: Int, color: RGBAColor, indexSize: Int) -> Int {
        guard let ptr = ptr else { return fromByteOffset }
        ptr.advanced(by: fromByteOffset)
           .initializeMemory(as: UInt32.self, repeating: color.argb8888, count: count)
        return fromByteOffset + count * indexSize
    }
    
    /// Set multiple pixels starting from byte offset to the same color
    /// - Parameters:
    ///   - base: Buffer start address
    ///   - fromByteOffset: Byte offset from base
    ///   - count: Number of pixels
    ///   - color: Color
    ///   - indexSize: Size of a pixel in byte
    /// - Returns: New byte offset
    @inline(__always)
    static func setPixels(base: UnsafeMutableRawPointer, fromByteOffset: Int, count: Int, color: RGBAColor, indexSize: Int) -> Int {
        base.advanced(by: fromByteOffset)
                .initializeMemory(as: UInt32.self, repeating: color.argb8888, count: count)
        return fromByteOffset + count * indexSize
    }
    
    /// Draw a horizontal line without updating drawing position
    func drawHLine(from: IPoint, to: Int, color: RGBAColor? = nil) {
        guard let ptr = ptr else { return }
        
        let c = color ?? self.color
        let index1 = getBufferIndex(from)
        guard index1 >= 0 else { return }
        //let index2 = getBufferIndex(min(to, width), from.y, clip: false)
        let count: Int = min(to, width) - from.x

        var pixel = c.argb8888
        memset_pattern4(ptr + index1, &pixel, count * 4)
    }
    
    /// Draw a vertical line without updating drawing position
    func drawVLine(from: IPoint, to: Int, color: RGBAColor? = nil) {
        let c = color ?? self.color
        let index1 = getBufferIndex(from)
        guard index1 >= 0 else { return }
        let index2 = getBufferIndex(from.x, min(to, height), clip: false)

        image.withUnsafeMutableBufferPointer { imagePtr in
            for i in stride(from: index1, to: index2, by: bytesPerLine) {
                imagePtr[i]     = c.redi
                imagePtr[i + 1] = c.greeni
                imagePtr[i + 2] = c.bluei
                imagePtr[i + 3] = c.alphai
            }
        }
    }

    /// Draw a filled rectangle
    func drawRectFill(from: IPoint, to: IPoint, color: RGBAColor? = nil) {
        let c = color ?? self.color
        var index1 = getBufferIndex(from)
        guard index1 >= 0 else { return }
        var index2 = getBufferIndex(min(to.x, width), min(to.y+1, height), clip: false)

        image.withUnsafeMutableBufferPointer { imagePtr in
            for _ in from.y...to.y {
                for i in stride(from: index1, to: index2, by: indexSize) {
                    if i >= imagePtr.count { break }
                    imagePtr[i]     = c.redi
                    imagePtr[i + 1] = c.greeni
                    imagePtr[i + 2] = c.bluei
                    imagePtr[i + 3] = c.alphai
                }
                index1 += bytesPerLine
                index2 += bytesPerLine
            }
        }
    }
    
}
