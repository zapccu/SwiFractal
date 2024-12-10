//
//  Graphics.swift
//  SwiFractal
//
//  Created by Dirk Braner on 16.11.24.
//

import SwiftUI
import Accelerate

class Graphics {
    // Dimensions of drawing area
    var width: Int
    var height: Int
    var size: CGSize
    
    var x: Int = 0
    var y: Int = 0
    var p = CGPoint()
    
    var isDrawing: Bool = false
    
    // Calculation of drawing time
    var startTime: Double = 0
    var endTime: Double = 0
    var drawTime: Double = 0
    
    // Construct graphics object
    init(_ size: CGSize) {
        self.size   = size
        self.width  = Int(size.width)
        self.height = Int(size.height)
    }
    
    func clear(_ color: RGBAColor) {
        // Override this function in child classes
    }
    
    func setColor(_ color: RGBAColor) {
        // Override this function in child classes
    }
        
    // Start drawing
    func beginDraw() -> Bool {
        startTime = Date().timeIntervalSince1970
        isDrawing = true
        return true
    }
    
    // End drawing
    func endDraw() -> Double {
        endTime = Date().timeIntervalSince1970
        drawTime = endTime - startTime
        isDrawing = false
        return drawTime
    }
    
    func moveTo(_ x: Int, _ y: Int) {
        self.x = x
        self.y = y
        self.p = CGPoint(x: Double(x), y: Double(y))
    }
    
    func moveTo(_ p: CGPoint) {
        self.p = p
        self.x = Int(p.x)
        self.y = Int(p.y)
    }
    
    func setPixel(_ x: Int, _ y: Int, _ color: RGBAColor) {
        // Override this function in child classes
    }
    
    func drawHLineTo(_ x: Int) {
        // Override this function in child classes
    }
    
    func drawVLineTo(_ y: Int) {
        // Override this function in child classes
    }
    
    // Save CGImage to file
    static func saveCGImage(cgimage: CGImage, to url: URL) -> Bool {
        let cicontext = CIContext()
        let ciimage = CIImage(cgImage: cgimage)
        print("Saving file to \(url.path)")
        do {
            try cicontext.writePNGRepresentation(of: ciimage, to: url, format: .RGBA8, colorSpace: ciimage.colorSpace!)
        } catch {
            return false
        }
        
        return true
    }
    
    // Save NSImage to file
    static func saveNSImage(image: NSImage, path: String) -> Bool {
        let imageRep = NSBitmapImageRep(data: image.tiffRepresentation!)
        let pngData = imageRep?.representation(using: NSBitmapImageRep.FileType.png, properties: [:])
        do {
            try pngData!.write(to: URL(filePath: path))
        } catch {
            return false
        }
        
        return true
    }
}

class CGGraphics : Graphics {
    var context: GraphicsContext
    var color = GraphicsContext.Shading.color(.sRGB, red: 0, green: 0, blue: 0)

    init(_ context: GraphicsContext, _ size: CGSize) {
        self.context = context
        super.init(size)
    }

    func beginDraw(drawAction: () -> Void) -> Bool {
        if super.beginDraw() {
            drawAction()
            return true
        }
        
        return false
    }
    
    /// Clear graphics
    override func clear(_ color: RGBAColor = .black) {
        setColor(color)
        drawRectFill(0, 0, width, height)
    }

    /// Set drawing color
    override func setColor(_ color: RGBAColor) {
        self.color = GraphicsContext.Shading.color(.sRGB, red: Double(color.red), green: Double(color.green), blue: Double(color.blue))
    }
    
    /// Set blending mode and return previous blending mode
    func setBlendMode(_ blendMode: GraphicsContext.BlendMode) -> GraphicsContext.BlendMode {
        let currentBlendMode = context.blendMode
        context.blendMode = blendMode
        return currentBlendMode
    }
    
    /// Draw a line
    func drawLine(_ from: CGPoint, _ to: CGPoint) {
        self.context.stroke(
            Path() { path in
                path.move(to: from)
                path.addLine(to: to)
            },
            with: color,
            lineWidth: 1
        )
        moveTo(to)
    }

    /// Draw a pixel at point
    func setPixel(_ point: CGPoint, _ color: RGBAColor) {
        setColor(color)
        moveTo(point)
        drawLine(p, CGPoint(x: x+1, y: y))
    }
    
    /// Draw a pixel at coordinates
    override func setPixel(_ x: Int, _ y: Int, _ color: RGBAColor) {
        setColor(color)
        moveTo(x, y)
        drawLine(p, CGPoint(x: x+1, y: y))
    }
    
    /// Draw a horizontal line
    override func drawHLineTo(_ x: Int) {
        drawLine(p, CGPoint(x: x, y: self.y))
    }
    
    /// Draw a vertical line
    override func drawVLineTo(_ y: Int) {
        drawLine(p, CGPoint(x: self.x, y: y))
    }
    
    /// Draw a rectangle
    func drawRect(_ rect: CGRect) {
        self.context.stroke(
            Path() { path in
                path.addRect(rect)
            },
            with: color,
            lineWidth: 1
        )
    }
    
    /// Draw a rectangle
    func drawRect(_ x1: Int, _ y1: Int, _ x2: Int, _ y2: Int) {
        self.context.stroke(
            Path() { path in
                path.addRect(CGRect(x: x1, y: y1, width: x2-x1, height: y2-y1))
            },
            with: color,
            lineWidth: 1
        )
    }

    // Draw a filled rectangle
    func drawRectFill(_ x1: Int, _ y1: Int, _ x2: Int, _ y2: Int) {
        for y in y1..<y2 {
            drawLine(CGPoint(x: x1, y: y), CGPoint(x: x2, y: y))
        }
    }
    
    /*
     // CGContexts like rowbytes that are multiples of 16.
     func goodBytesPerRow(_ width: Int) -> Int {
         return (((width * 4) + 15) / 16) * 16
     }

     func drawMyImage() -> CGImage? {
         let bounds = CGRect(x: 0, y:0, width: 200, height: 200)
         let intWidth = Int(ceil(bounds.width))
         let intHeight = Int(ceil(bounds.height))
         let bitmapContext = CGContext(data: nil,
                                       width: intWidth, height: intHeight,
                                       bitsPerComponent: 8,
                                       bytesPerRow: goodBytesPerRow(intWidth),
                                       space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                       bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)

         if let cgContext = bitmapContext {
             cgContext.saveGState()
             cgContext.setFillColor(gray: 0, alpha: 1.0)
             cgContext.fill(bounds)

             /* ... do other drawing here ... */

             cgContext.restoreGState()

             return cgContext.makeImage()
         }

         return nil
     }

     let image = drawMyImage()
     */
}

typealias VImage = vImage.PixelBuffer<vImage.Interleaved8x4>
typealias ImagePtr = UnsafeMutableBufferPointer<vImage.Interleaved8x4.ComponentType>
                                                    
class ImageGraphics : Graphics {
    var rowBytes: Int = 0
    var imagePtr: ImagePtr?
    var image: VImage?
    
    // Current drawing color (red, green, blue, alpha)
    var color: RGBAI = RGBAI(0, 0, 0, 255)
    
    /// Initialize ImageGraphics object
    override init(_ size: CGSize) {
        super.init(size)
        
        // Create buffer
        image = vImage.PixelBuffer<vImage.Interleaved8x4>(width: Int(size.width), height: Int(size.height))
        rowBytes = image!.rowStride * image!.channelCount
        
        // Initialize buffer with black color
        image!.withUnsafeMutableBufferPointer { imagePtr in
            initBuffer(imagePtr)
        }
    }
   
    /// Calculate buffer index from coordinates
    func getBufferIndex(_ x: Int, _ y: Int) -> Int {
        return y * rowBytes + x * image!.channelCount
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
    
    func beginDraw(drawAction: () -> Void) -> Bool {
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
    
    // Clear graphics
    override func clear(_ color: RGBAColor = .black) {
        guard isDrawing else { return }
        initBuffer(imagePtr!, color)
    }

    override func setColor(_ color: RGBAColor) {
        self.color = color.rgbai
    }
    
    override func setPixel(_ x: Int, _ y: Int, _ color: RGBAColor) {
        guard isDrawing else { return }

        let index = getBufferIndex(x, y)
        imagePtr![index]     = color.redi
        imagePtr![index + 1] = color.greeni
        imagePtr![index + 2] = color.bluei
        imagePtr![index + 3] = color.alphai
    }
    
    // Draw a horizontal line
    override func drawHLineTo(_ x: Int) {
        guard isDrawing else { return }
        
        let index1 = getBufferIndex(self.x, self.y)
        let index2 = getBufferIndex(x, self.y)
        for i in stride(from: index1, to: index2, by: image!.channelCount) {
            imagePtr![i]     = color.red
            imagePtr![i + 1] = color.green
            imagePtr![i + 2] = color.blue
            imagePtr![i + 3] = color.alpha
        }
        
        moveTo(x, self.y)
    }
    
    // Draw a vertical line
    override func drawVLineTo(_ y: Int) {
        guard isDrawing else { return }

        let index1 = getBufferIndex(self.x, self.y)
        let index2 = getBufferIndex(self.x, y)
        for i in stride(from: index1, to: index2, by: rowBytes) {
            imagePtr![i]     = color.red
            imagePtr![i + 1] = color.green
            imagePtr![i + 2] = color.blue
            imagePtr![i + 3] = color.alpha
        }
        
        moveTo(self.x, y)
    }
    
    // Draw a filled rectangle
    func drawRectFill(_ x1: Int, _ y1: Int, _ x2: Int, _ y2: Int) {
        guard isDrawing else { return }

        var index1 = getBufferIndex(x1, y)
        let index2 = getBufferIndex(x2, y)
        for _ in y1..<y2 {
            for i in stride(from: index1, to: index2, by: image!.channelCount) {
                imagePtr![i]     = color.red
                imagePtr![i + 1] = color.green
                imagePtr![i + 2] = color.blue
                imagePtr![i + 3] = color.alpha
            }
            index1 += rowBytes
        }
    }
    
    func renderImage(renderAction: (_ imagePtr: ImagePtr, _ index: Int, _ x: Int, _ y: Int) -> Void) {
        var rowIndex: Int = 0
        
        for y in 0..<height {
            var colIndex: Int = 0
            for x in 0..<width {
                renderAction(imagePtr!, rowIndex + colIndex, x, y)
                colIndex += image!.byteCountPerPixel
            }
            
            rowIndex += rowBytes
        }
    }
    
    // Convert image buffer to CGImage
    func getCGImage(_ rect: CGRect = .zero) -> CGImage? {
        let format = vImage_CGImageFormat(bitsPerComponent: 8, bitsPerPixel: 32, colorSpace: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue))!
        let cgImage = image!.makeCGImage(cgImageFormat: format)
        return rect != .zero ? cgImage?.cropping(to: rect) : cgImage
    }
    
    // Draw image into graphics context
    func drawImage(_ context: GraphicsContext) {
        if let cgImage = getCGImage() {
            let nsImage = NSImage(cgImage: cgImage, size: size)
            context.draw(Image(nsImage: nsImage), at: CGPoint(x: 0, y: 0), anchor: .zero)
        }
    }
}

extension Image {
    init(_ image: VImage) {
        let format = vImage_CGImageFormat(bitsPerComponent: 8, bitsPerPixel: 32, colorSpace: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue))!
        let cgImage = image.makeCGImage(cgImageFormat: format)
        let size = CGSize(width: image.width, height: image.height)
        let nsImage = NSImage(cgImage: cgImage!, size: size)
        self.init(nsImage: nsImage)
    }
}
