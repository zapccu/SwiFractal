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
        /*
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
        )*/
        let format = vImage_CGImageFormat(
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            colorSpace: colorSpace,
            bitmapInfo:  CGBitmapInfo(
                rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
            )
        )

        /*
        let result = vImageCreateCGImageFromBuffer(
            &dstBuffer,
            &format,
            nil, nil,
            vImage_Flags(kvImageNoFlags),
            &error
        )*/
        do {
            let result = try dstBuffer.createCGImage(format: format!)
            return result
        } catch {
            return nil
        }

    }

}
