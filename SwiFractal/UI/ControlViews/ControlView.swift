//
//  ControlView.swift
//  SwiFractal
//
//  Created by Dirk Braner on 22.03.26.
//

import SwiftUI

struct ControlView<T: FractalData>: View {
    var fractal: Fractal<T>
    var graphics: Graphics

    // Bindings from parent view
    @Binding var resolution: CGSize
    @Binding var redraw: Bool
    @Binding var currentAction: String
    @Binding var selection: Selection
    @Binding var isDrawing: Bool
    @Binding var message: String


    var body: some View {
        ScrollView([.vertical]) {
            VStack(alignment: .leading) {
                
                // Buttons
                ControlButtonView(fractal: fractal, graphics: graphics, selection: selection,
                                  currentAction: $currentAction, message: $message,
                                  isDrawing: $isDrawing, redraw: $redraw)
                
                // Common controls
                ControlCommonView(fractal: fractal, resolution: $resolution)
                
                // Specific view
                if let mandelbrot = fractal as? Mandelbrot {
                    ControlMandelbrotView(fractal: mandelbrot, graphics: graphics)
                }
            }
        }
    }
}
