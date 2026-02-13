//
//  Graphics.swift
//
//  Implementation of drawing functions
//
//  Part of SwiFractal
//
//  Created by Dirk Braner on 16.11.24.
//

import SwiftUI
import Accelerate


// ------------------------------------------------------------------
//  Class Graphics
//
//  Base class for drawing functions
// ------------------------------------------------------------------

class Graphics {
    // Resulting image, created/updated by function endDraw()
    var cgImage: CGImage? = nil
    
    // Dimensions of drawing area
    var size: CGSize                        // Oversampling size
    var frameSize: CGSize                   // Size of the surrounding frame
    var width: Int { Int(size.width) }      // Return oversampling width as integer
    var height: Int { Int(size.height) }    // Return oversampling height as integer
    
    // Oversampling
    let oversampling: Int
    
    // Current drawing position
    var p = CGPoint()
    var x: Int { Int(p.x) }
    var y: Int { Int(p.y) }
    
    // Current drawing color
    var color: RGBAColor = .black
        
    // Flag for drawing in progress
    var isDrawing: Bool = false
    
    // Calculation of drawing time
    var startTime: Double = 0
    var endTime:   Double = 0
    var drawTime:  Double = 0

    /// Construct graphics object
    init(_ size: CGSize, oversampling: Int = 1) {
        self.oversampling = max(min(oversampling, 3), 1)
        self.frameSize = size
        self.size = CGSize(width: size.width * Double(self.oversampling), height: size.height * Double(self.oversampling))
    }

    /// Clear graphics, fill with color
    func clear(color: RGBAColor? = nil) {
        drawRectFill(0, 0, width, height, color: color)
    }
    
    /// Set drawing color
    func setColor(_ color: RGBAColor) {
        self.color = color
    }
        
    /// Start drawing
    func beginDraw() -> Bool {
        startTime = Date().timeIntervalSince1970
        isDrawing = true
        cgImage = nil
        return true
    }
    
    /// Start drawing and call the draw action
    func beginDraw(drawAction: () -> Void) -> Bool {
        if beginDraw() {
            drawAction()
            return true
        }
        
        return false
    }
    
    /// End drawing
    func endDraw() -> Double {
        updateCGImage()
        endTime = Date().timeIntervalSince1970
        drawTime = endTime - startTime
        isDrawing = false
        return drawTime
    }
    
    /// Move drawing position to specified coordinates
    func moveTo(_ x: Int, _ y: Int) {
        self.p = CGPoint(x: Double(x), y: Double(y))
    }
    
    /// Move drawing position to specified point
    func moveTo(_ p: CGPoint) {
        self.p = p
    }
    
    /// Set pixel to color without modifiying drawing position
    func setPixel(_ x: Int, _ y: Int, color: RGBAColor? = nil) {
        // Override this function in child classes for better performance
        _ = drawLine(p, CGPoint(x: x+1, y: y), color: color)
    }
    
    /// Draw a line without modifiying drawing position
    func drawLine(_ from: CGPoint, _ to: CGPoint, color: RGBAColor? = nil) -> CGPoint {
        // All default drawing functions are using this function
        // This function must(!) be overridden in child classes
        return to
    }
    
    /// Draw a line from drawing position to point and update drawing position
    func drawLineTo(_ to: CGPoint, color: RGBAColor? = nil) -> CGPoint {
        let p = drawLine(p, to, color: color)
        moveTo(to)
        return p
    }
    
    /// Draw a horizontal line without modifiying drawing position
    func drawHLine(_ from: CGPoint, _ to: Int, color: RGBAColor? = nil) -> CGPoint {
        return drawLine(from, CGPoint(x: to, y: Int(from.y)), color: color)
    }

    /// Draw a horizontal line from drawing position to X coordinate and update drawing position
    func drawHLineTo(_ x: Int, color: RGBAColor? = nil) -> CGPoint {
        return drawLineTo(CGPoint(x: x, y: self.y), color: color)
    }

    /// Draw a vertical line without modifiying drawing position
    func drawVLine(_ from: CGPoint, _ to: Int, color: RGBAColor? = nil) -> CGPoint {
        return drawLine(from, CGPoint(x: Int(from.x), y: to), color: color)
    }

    /// Draw a vertical line from drawing position to Y coordinate and update drawing position
    func drawVLineTo(_ y: Int, color: RGBAColor? = nil) -> CGPoint {
        return drawLineTo(CGPoint(x: self.x, y: y), color: color)
    }
    
    // Draw a rectangle
    func drawRect(_ rect: CGRect, color: RGBAColor? = nil) {
        // Override this function in child classes for better performance
        drawRect(Int(rect.origin.x), Int(rect.origin.y), Int(rect.maxX), Int(rect.maxY), color: color)
    }
    
    /// Draw a rectangle
    func drawRect(_ x1: Int, _ y1: Int, _ x2: Int, _ y2: Int, color: RGBAColor? = nil) {
        // Override this function in child classes for better performance
        _ = drawLine(CGPoint(x: x1, y: y1), CGPoint(x: x2, y: y1), color: color)
        _ = drawLine(CGPoint(x: x2, y: y1), CGPoint(x: x2, y: y2), color: color)
        _ = drawLine(CGPoint(x: x2, y: y2), CGPoint(x: x1, y: y2), color: color)
        _ = drawLine(CGPoint(x: x1, y: y2), CGPoint(x: x1, y: y1), color: color)
    }
    
    /// Draw a filled rectangle
    func drawRectFill(_ x1: Int, _ y1: Int, _ x2: Int, _ y2: Int, color: RGBAColor? = nil) {
        // Override this function in child classes for better performance
        for y in y1...y2 {
            _ = drawLine(CGPoint(x: x1, y: y), CGPoint(x: x2, y: y), color: color)
        }
    }

    /// Init view from RGBAColor array
    func initFromColorArray(_ colors: UnsafeBufferPointer<RGBA>) {
        guard isDrawing else { return }
        
        for y in 0..<height {
            for x in 0..<width {
                let offset = y * width + x
                if offset >= colors.count { return }
                setPixel(x, y, color: RGBAColor(colors[offset]))
            }
        }
    }
    
    /// Create a CGImage from Graphics object
    /// This function is called from endDraw()
    /// This funct must(!) be overriden in child classes to create a valid cgImage
    func updateCGImage() {
        cgImage = nil
    }
    
    /// Return cgImage
    func getCGImage() -> CGImage? {
        // Override this function in child classes if needed
        return cgImage
    }
    
    /// Scale image to destination frame size and draw image into a graphics context
    func drawImage(_ context: GraphicsContext) {
        if cgImage != nil {
            // let nsImage = NSImage(cgImage: cgImage!, size: size)
            // let img = Image(nsImage: nsImage).resizable().interpolation(.high) //.frame(width: frameSize.width, height: frameSize.height, alignment: .topLeading)
            context.draw(Image(decorative: cgImage!, scale: 1.0, orientation: .downMirrored), at: CGPoint(x: 0, y: 0), anchor: .zero)
            // context.draw(img, at: .zero, anchor: .topLeading)
            //context.draw(img, in: CGRect(origin: .zero, size: frameSize))
        }
        else {
            print("No image to draw")
        }
    }

}


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
    override func beginDraw(drawAction: () -> Void) -> Bool {
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
    override func beginDraw(drawAction: () -> Void) -> Bool {
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


