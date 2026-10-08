//
//  ContentView.swift
//  SwiFractal
//
//  Created by Dirk Braner on 15.11.24.
//

import SwiftUI
import SwiftMPx


///
/// Content view
///
/// Container for preset view, drawing view, status view and control view
///
struct ContentView: View {

    /// The fractal controller object
    @State private var controller: FractalController
    
    // Adjust either complex or image resolution to match aspect ratio
    @State private var fit: AspectRatioMode = .fitToFractalSize
    
    /// Initialize ContentView
    init() {
        _controller = State(initialValue: FractalController())
    }
    
    var body: some View {

        HStack(spacing: 0) {
            VStack(spacing: 0) {
                // Picker for fractal type and fractal parameter preset
                PresetView(controller: controller)
                    .frame(maxWidth: .infinity, minHeight: 40,alignment: .init(horizontal: .center, vertical: .center))
                    .background(Color.yellow.opacity(0.5)).clipped()

                // Make drawing view scrollable
                ScrollView([.horizontal, .vertical], showsIndicators: true) {
                    // The drawing view
                    DrawingView(controller: controller)
                        .overlay(
                            // Selection view on top of the drawing view
                            // SelectionView(controller: controller, selection: $selection)
                            SelectionView(controller: controller)
                                .onContinuousHover { phase in
                                    controller.cursorLocation.onHover(phase: phase)
                                    controller.info.mousePosition = controller.fmtScreenLocation + " " + controller.fmtComplexLocation
                                }
                        )
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
                .background(Color(CGColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)))
                
                // The status view
                StatusView(controller: controller)
                    .frame(height: 25)
                    .frame(maxWidth: .infinity)
            }
            
            ControlView(controller: controller)
                .frame(width: FractalAppData.controlViewWidth)
        }
    }
    
}




