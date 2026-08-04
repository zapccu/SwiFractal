//
//  ContentView.swift
//  SwiFractal
//
//  Created by Dirk Braner on 15.11.24.
//

import SwiftUI
import SwiftMPx


//
// Information displayed in StatusView
//
struct Info {
    var currentAction: String = "Idle"
    var statusMessage: String = "Ready."
    var mousePosition: String = "X: 0, Y: 0, R: 0, I: 0"
    
    mutating func setState(currentAction: String, statusMessage: String = "") {
        self.currentAction = currentAction
        self.statusMessage = statusMessage
    }
}

//
// Content view
//
// Container for preset view, drawing view, status view and control view
//
struct ContentView: View {
    var resolution: CGSize
    
    @State private var info: Info = Info()
    //@State private var selection = Selection(fromMidPoint: false, keepAspectRatio: true)
    
    // The fractal controller object
    @State private var controller: FractalController
    
    // Adjust either complex or image resolution to match aspect ratio
    @State private var fit: AspectRatioMode = .fitToFractalSize
    
    /// Initialize ContentView
    init(resolution: CGSize) {
        self.resolution = resolution
        _controller = State(initialValue: FractalController(resolution: resolution))
    }
    
    var body: some View {

        HStack(spacing: 0) {
            VStack(spacing: 0) {
                // Picker for fractal type and fractal parameter preset
                PresetView(controller: controller)
                    .frame(height: 30, alignment: .init(horizontal: .center, vertical: .center))
                
                // Make drawing view scrollable
                ScrollView([.horizontal, .vertical], showsIndicators: true) {
                    ZStack {
                        // The drawing view
                        DrawingView(controller: controller)
                        
                        // Selection view on top of the drawing view
                        // SelectionView(controller: controller, selection: $selection)
                        SelectionView(controller: controller)
                            .onContinuousHover { phase in
                                // Update the cursor position
                                switch phase {
                                case .active(let location):
                                    let (posX, posY, strFrcX, strFrcY) = controller.mapPointFormatted(location)
                                    info.mousePosition = "X: \(posX), Y: \(posY), R: \(strFrcX), I: \(strFrcY)"
                                case .ended:
                                    info.mousePosition = "X: 0, Y: 0, R: 0, I: 0"
                                    break
                                }
                            }
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
                .background(Color(CGColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)))
                
                // The status view
                StatusView(info: $info)
                    .frame(height: 25)
                    .frame(maxWidth: .infinity)
            }
            
            //ControlView(controller: controller, selection: $selection, info: $info)
            ControlView(controller: controller, info: $info)
                .frame(width: FractalAppData.controlViewWidth)
        }
    }
    
}




