//
//  GraphicsExt.swift
//  SwiFractal
//
//  Created by Dirk Braner on 06.01.25.
//

import SwiftUI
import Accelerate

typealias VImage = vImage.PixelBuffer<vImage.Interleaved8x4>
typealias ImagePtr = UnsafeMutableBufferPointer<vImage.Interleaved8x4.ComponentType>


extension CGImage {
    
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
}

extension NSImage {
    
    // Save NSImage to file
    func saveToFile(path: String) -> Bool {
        let imageRep = NSBitmapImageRep(data: self.tiffRepresentation!)
        let pngData = imageRep?.representation(using: NSBitmapImageRep.FileType.png, properties: [:])
        do {
            try pngData!.write(to: URL(filePath: path))
        } catch {
            return false
        }
        
        return true
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
