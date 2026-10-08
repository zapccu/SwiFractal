//
//  ImageGraphics.swift
//  SwiFractal
//
//  Created by Dirk Braner on 23.02.26.
//

import Foundation
import SwiftUI
import Accelerate


typealias VImage = vImage.PixelBuffer<vImage.Interleaved8x4>
typealias ImagePtr = UnsafeMutableBufferPointer<vImage.Interleaved8x4.ComponentType>


///
///  Draw into vImage buffer
///
final class ImageGraphics : MemoryGraphicsProtocol {
        
    /// Size considering oversampling factor
    var size: ISize
    
    /// Frame size without oversampling
    var frameSize: ISize
    
    /// Flip on Y-axis
    var flip: Bool
        
    /// Current drawing position
    var pos: IPoint = .zero
    
    /// Current drawing index
    var index: Int = 0
        
    /// Drawing color
    var color: RGBAColor = .white
    
    /// Bytes per row including padding bytes
    let bytesPerLine: Int
    
    let lastIndex: Int
    
    /// Bytes per pixel
    var indexSize: Int
    
    /// The vImage
    var image: vImage.PixelBuffer<vImage.Interleaved8x4>
    
    /// Pointer for direct read/write. Initialized by beginDraw()
    var ptr: UnsafeMutableRawPointer?
    
    /// Return oversampling state
    var oversampling: Bool { frameSize != size }

    /// Create CGImage from image buffer scaled to destination frame size. nil on error
    var cgImage: CGImage? {

        let cgImageFormat = vImage_CGImageFormat(
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            colorSpace: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.first.rawValue),
            renderingIntent: .defaultIntent
        )!

        let destination: vImage.PixelBuffer<vImage.Interleaved8x4>

        if oversampling {
            destination = vImage.PixelBuffer<vImage.Interleaved8x4>(
                width: frameSize.width,
                height: frameSize.height
            )

            do {
                try image.withUnsafePointerToVImageBuffer { src in
                    try destination.withUnsafePointerToVImageBuffer { dst in
                        let error = vImageScale_ARGB8888(src, dst, nil,
                            vImage_Flags(kvImageHighQualityResampling))
                        guard error == kvImageNoError else {
                            throw NSError(domain: "vImage", code: Int(error))
                        }
                    }
                }
            } catch {
                return nil
            }
        } else {
            destination = image
        }

        // Flip vertically
        if flip {
            do {
                try destination.withUnsafePointerToVImageBuffer { buf in
                    let error = vImageVerticalReflect_ARGB8888(buf, buf, vImage_Flags(kvImageNoFlags))
                    guard error == kvImageNoError else {
                        throw NSError(domain: "vImage", code: Int(error))
                    }
                }
            } catch {
                return nil
            }
        }

        return destination.makeCGImage(cgImageFormat: cgImageFormat)
    }
    
    /// Initialize ImageGraphics object
    /// - Parameters:
    ///   - frameSize: Final image size without oversampling
    ///   - size: Image size considering oversampling factor
    ///   - flip: If true, cgImage will return a vertically flipped image
    init(frameSize: CGSize, size: ISize, flip: Bool = false) {
        self.frameSize = ISize(size: frameSize)
        self.size = size
        self.flip = flip
        
        // Create image buffer
        self.image = vImage.PixelBuffer<vImage.Interleaved8x4>(width: self.size.width, height: self.size.height)
        
        // Calculate number of bytes per line
        self.bytesPerLine = image.rowStride * image.channelCount
        self.lastIndex = (size.height - 1) * bytesPerLine + (size.width - 1) * image.channelCount
        self.indexSize = image.channelCount
        
        // Initialize buffer with black color
        clear(color: .black)
    }
    
    /// Start drawing. Initialize pointer to image buffer and call drawing action.
    /// - Parameter drawAction: Drawing action (closure)
    /// - Returns: Image
    func beginDraw(drawAction: () -> CGImage?) -> CGImage? {
        return image.withUnsafeMutableBufferPointer { imagePtr in
            self.pos = .zero
            self.index = 0
            self.ptr = UnsafeMutableRawPointer(imagePtr.baseAddress!)
            
            let cgImage = drawAction()
            
            self.ptr = nil
            return cgImage
        }
    }
    
    /// Set current drawing position
    /// - Parameter to: Position
    @inline(__always) func move(to point: IPoint) {
        guard ptr != nil && !clipped(point) else { return }
        pos = point
        index = getIndex(point)
    }
    
    /// Increment row position
    /// - Parameter pixels: Number of pixels
    /// - Note: If new column would be greater than width-1, increment row and set column to 0.\
    /// If new position would exceed (width-1,height-1), set position to (0,0)
    func incrementX(by pixels: Int) {
        pos.x += pixels
        if pos.x >= width {
            pos.x = 0
            pos.y = pos.y == height - 1 ? 0 : pos.y + 1
            self.index = pos.y * bytesPerLine
        }
        else {
            self.index += pixels * indexSize
        }
    }
    
    /// Increment column position
    /// - Parameter pixels: Number of pixels
    /// - Note: If new row would be greater than height-1, increment column and set row to 0.\
    /// If new position would exceed (width-1,height-1), set position to (0,0)
    func incrementY(by pixels: Int) {
        pos.y += pixels
        if pos.y >= height {
            pos.y = 0
            pos.x = pos.x == width - 1 ? 0 : pos.x + 1
            self.index = pos.x * indexSize
        }
        else {
            self.index += bytesPerLine
        }
    }

    /// Clear graphics
    /// - Parameter color: Color
    @inline(__always) func clear(color: RGBAColor = .black) {
        image.withUnsafePointerToVImageBuffer { iptr in
            _ = vImageBufferFill_ARGB8888(iptr, color.pixel, vImage_Flags(kvImageNoFlags))
        }
    }
    
    /// Set a pixel at index
    /// - Parameters:
    ///   - index: Offset in buffer
    ///   - color: Color. Default = nil (use current color)
    /// - Note: No check for writing into padding bytes.
    @inline(__always) func setPixel(_ index: Int, color: RGBAColor? = nil) {
        guard let ptr = ptr else { return }
        guard index >= 0 && index <= lastIndex else { return }
        
        let c = color ?? self.color
        ptr.storeBytes(of: c.argb8888, toByteOffset: index, as: UInt32.self)
    }
    
    /// Set a pixel at coordinates
    /// - Parameters:
    ///   - x: X coordinate
    ///   - y: Y coordinate
    ///   - color: Color. If nil use current color
    @inline(__always) func setPixel(_ x: Int, _ y: Int, color: RGBAColor? = nil) {
        guard let ptr = ptr else { return }
        guard !clipped(x, y) else { return }
        
        let index = getIndex(x, y)
        let c = color ?? self.color
        ptr.storeBytes(of: c.argb8888, toByteOffset: index, as: UInt32.self)
    }
    
    /// Draw multiple pixels into current row starting from current index. Update drawing position.
    /// - Parameters:
    ///   - count: Number of pixels
    ///   - color: Color. Default = nil: Use current color
    /// - Note: Drawing position will be wrapped when end of row was exceeded
    func drawHLine(count: Int, color: RGBAColor? = nil) {
        guard let ptr = ptr else { return }
        guard index >= 0 && index <= lastIndex && count > 0 else { return }
        
        let pixels = min(pos.x + count, width) - pos.x
        
        let c = color ?? self.color
        ptr.advanced(by: index)
           .initializeMemory(as: UInt32.self, repeating: c.argb8888, count: pixels)
        
        incrementX(by: pixels)
    }
    
    /// Draw multiple pixels into current column starting from current index. Update drawing position.
    /// - Parameters:
    ///   - count: Number of pixels
    ///   - color: Color. Default = nil: Use current color
    /// - Note: Drawing position will be wrapped when end of column was exceeded
    func drawVLine(count: Int, color: RGBAColor? = nil) {
        guard let ptr = ptr else { return }
        guard index >= 0 && index <= lastIndex && count > 0 else { return }

        let pixels = min(pos.y + count, height) - pos.y
        
        var idx = index
        let c = color ?? self.color
        for _ in 0..<pixels {
            ptr.storeBytes(of: c.argb8888, toByteOffset: idx, as: UInt32.self)
            idx += bytesPerLine
        }
        
        incrementY(by: pixels)
    }
    
    /// Draw a horizontal line excluding *to* with clipping at the end.
    /// - Parameters:
    ///   - from: First point of line. Must be inside view.
    ///   - to: Last point in row
    ///   - color: <#color description#>
    func drawHLine(from: IPoint, to x: Int, color: RGBAColor? = nil) {
        guard !clipped(from) else { return }
        guard from.x < x else { return }

        move(to: from)
        drawHLine(count: x - from.x, color: color)
    }
    
    /// Draw a vertical line excluding *to* with clipping at the end
    /// - Parameters:
    ///   - from: First point of line. Must be inside view.
    ///   - to: Last point in column
    ///   - color: Color
    func drawVLine(from: IPoint, to y: Int, color: RGBAColor? = nil) {
        guard !clipped(from) else { return }
        guard from.y < y else { return }

        move(to: from)
        drawVLine(count: y - from.y, color: color)
    }
    
    /// Draw a rectangle with clipping
    /// - Parameters:
    ///   - rect: Rectangle
    ///   - color: Color
    func drawRect(_ rect: IRect, color: RGBAColor? = nil) {
        let stdRect = rect.cgRect.standardized
        let clpRect = IRect(rect: stdRect.intersection(CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height))))
        
        drawHLine(from: clpRect.origin, to: clpRect.origin.x + clpRect.width, color: color)
        drawVLine(count: clpRect.height, color: color)
        drawVLine(from: clpRect.origin, to: clpRect.origin.y + clpRect.height, color: color)
        drawHLine(count: clpRect.width, color: color)
    }
    
}
