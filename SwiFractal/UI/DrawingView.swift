//
//  DrawingView.swift
//  SwiFractal
//
//  Created by Dirk Braner on 11.02.26.
//

import SwiftUI

//
// Drawing View
//
// Graphical output of the current fractal
//
struct DrawingView: View {

    var controller: FractalController
        
    var body: some View {
        Canvas { context, size in
            let graphics = CanvasGraphics(context: context, size: size)
            debugPrint ("drawing cached image")
            if controller.isImageZoomed {
                // Draw zoomed image if available
                if let cgImage = controller.zoomedImage {
                    graphics.drawImage(cgImage: cgImage)
                }
            }
            else {
                // Draw fractal image if available
                if let cgImage = controller.image {
                    graphics.drawImage(cgImage: cgImage)
                }
            }
        }
        .frame(width: controller.resolution.width, height: controller.resolution.height, alignment: .topLeading)
        .background(Color.gray.opacity(0.8))
    }
}
