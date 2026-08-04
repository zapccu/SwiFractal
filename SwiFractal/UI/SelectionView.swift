//
//  SelectionView.swift
//  SwiFractal
//
//  Created by Dirk Braner on 11.02.26.
//

import SwiftUI

//
// Selection View
//
// Placed on top of the drawing view for interactively selecting a view area
//
struct SelectionView: View {
    var controller: FractalController

    //@Binding var selection: Selection

    private func handleSelection() -> some Gesture {
        return DragGesture(minimumDistance: 0)
            .onChanged { event in
                controller.selection.onChanged(event, CGRect(origin: .zero, size: controller.resolution))
            }
            .onEnded{ event in
                controller.selection.onEnded(event, CGRect(origin: .zero, size: controller.resolution))
                let area = controller.selection.getArea(flipped: true, height: Int(controller.resolution.height))
                let dimensionsPrecision = controller.dimensions.zoomArea(area: area, resolution: controller.resolution)
                
                switch dimensionsPrecision {
                case .double(let dim):
                    controller.dimensions = dim.asMPFloat
                case .mpfloat(let dim):
                    controller.dimensions = dim
                }
                
                controller.selection.reset()
                controller.zoomImage(area: area)
            }
    }

    var body: some View {
        Canvas { context, size in
            let graphics = CanvasGraphics(context: context, size: size)
            controller.selection.draw(graphics)
        }
        .gesture(controller.handleSelection())
        //.gesture(handleSelection())
    }
}
