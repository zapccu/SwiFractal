//
//  ImageExt.swift
//  SwiFractal
//
//  Created by Dirk Braner on 30.04.26.
//

import SwiftUI
import Accelerate

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
