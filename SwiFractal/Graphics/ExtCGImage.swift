//
//  CGImageExt.swift
//  SwiFractal
//
//  Created by Dirk Braner on 30.04.26.
//

import SwiftUI
import Accelerate


extension CGImage {
    
    /// Convert CGImage to SwiftUI Image
    var suiImage: Image {
        Image(decorative: self, scale: 1.0).interpolation(.high)
    }
    
    /// Create a CGImage from RGBAColor array
    static func fromRGBAColorArray(_ bytes: [RGBAColor], width: Int, height: Int) -> CGImage? {
        return bytes.withUnsafeBytes { ptr in
            let context = CGContext(data: UnsafeMutableRawPointer(mutating: ptr.baseAddress!),
                                    width: width, height: height,
                                    bitsPerComponent: 8, bytesPerRow: width * 4,
                                    space: CGColorSpaceCreateDeviceRGB(),
                                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            return context?.makeImage()
        }
    }
    
    /// Create CGImage from vImage Interleave8x4
    static func fromVImage(_ image: VImage) -> CGImage? {
        let format = vImage_CGImageFormat(bitsPerComponent: 8, bitsPerPixel: 32, colorSpace: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue))!
        return image.makeCGImage(cgImageFormat: format)
    }
    
    /// Draw CGImage into graphics context
    func draw(_ context: GraphicsContext) {
        let nsImage = NSImage(cgImage: self, size: CGSize(width: width, height: height))
        context.draw(Image(nsImage: nsImage), at: CGPoint(x: 0, y: 0), anchor: .zero)
    }
    
    // Save CGImage to file
    func saveToFile(to url: URL) -> Bool {
        let cicontext = CIContext()
        let ciimage = CIImage(cgImage: self)
        print("Saving file to \(url.path)")
        do {
            try cicontext.writePNGRepresentation(of: ciimage, to: url, format: .RGBA8, colorSpace: ciimage.colorSpace!)
        } catch {
            return false
        }
        
        return true
    }

    /// Crop CGImage to 'area' and scale it to 'frameSize'
    /// - Parameters:
    ///   - area:      Ausschnitt in Pixelkoordinaten (Integer-genau)
    ///   - frameSize: Target resolution
    func zoomImage(area: CGRect, frameSize: CGSize) -> CGImage? {
        // Crop image
        guard let cropped = self.cropping(to: area) else { return nil }

        let srcW = cropped.width
        let srcH = cropped.height
        let dstW = Int(frameSize.width)
        let dstH = Int(frameSize.height)

        // Create source buffer from cropped image
        guard let colorSpace = cropped.colorSpace,
              let srcCtx = CGContext(
                  data: nil,
                  width:            srcW,
                  height:           srcH,
                  bitsPerComponent: 8,
                  bytesPerRow:      0,
                  space:            colorSpace,
                  bitmapInfo:       CGImageAlphaInfo.premultipliedFirst.rawValue
                                    | CGBitmapInfo.byteOrder32Little.rawValue
              )
        else { return nil }

        srcCtx.draw(cropped, in: CGRect(x: 0, y: 0, width: srcW, height: srcH))

        guard let srcPtr = srcCtx.data else { return nil }

        var srcBuffer = vImage_Buffer(
            data:     srcPtr,
            height:   vImagePixelCount(srcH),
            width:    vImagePixelCount(srcW),
            rowBytes: srcCtx.bytesPerRow
        )

        // Allocate destination buffer
        var dstBuffer = vImage_Buffer()
        var error = vImageBuffer_Init(
            &dstBuffer,
            vImagePixelCount(dstH),
            vImagePixelCount(dstW),
            32,                         // bits per pixel (BGRA8)
            vImage_Flags(kvImageNoFlags)
        )
        guard error == kvImageNoError else { return nil }
        defer { free(dstBuffer.data) }

        // Scale with Lanczos5 for best quality
        error = vImageScale_ARGB8888(
            &srcBuffer,
            &dstBuffer,
            nil,
            vImage_Flags(kvImageHighQualityResampling)
        )
        guard error == kvImageNoError else { return nil }

        // vImage_Buffer → CGImage
        var format = vImage_CGImageFormat(
            bitsPerComponent: 8,
            bitsPerPixel:     32,
            colorSpace:       Unmanaged.passRetained(colorSpace),
            bitmapInfo:       CGBitmapInfo(rawValue:
                                  CGImageAlphaInfo.premultipliedFirst.rawValue
                                  | CGBitmapInfo.byteOrder32Little.rawValue),
            version:          0,
            decode:           nil,
            renderingIntent:  .defaultIntent
        )

        let result = vImageCreateCGImageFromBuffer(
            &dstBuffer,
            &format,
            nil, nil,
            vImage_Flags(kvImageNoFlags),
            &error
        )
        guard error == kvImageNoError else { return nil }

        return result?.takeRetainedValue()
    }

}
