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
    var lightningParameters: LightningParameters {
        controller.fractal.getLightningParameters()
    }
        
    var body: some View {
        Group {
            if let cgImage = controller.image {
                Image(cgImage, scale: 1, label: Text(""))
                    .resizable()
                    .interpolation(.high)
                }
            }
            .frame(width: controller.resolution.width, height: controller.resolution.height, alignment: .topLeading)
            .layerEffect(
                ShaderLibrary.planetEffect(
                    .float2(Float(controller.resolution.width), Float(controller.resolution.height)),
                    .float(controller.isSphericalDisplay ? 1.0 : 0.0),
                    .float(Float(lightningParameters.angle).deg2rad),
                    .float(Float(lightningParameters.elevation).deg2rad)
                ),
                maxSampleOffset: CGSize(
                    width: controller.resolution.width / 2,
                    height: controller.resolution.height / 2
                ),
                isEnabled: controller.isSphericalDisplay
            )
            .background(Color.gray.opacity(0.8))
        
        /*
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
         */
    }
}
