//
//  ContentView.swift
//  SwiFractal
//
//  Created by Dirk Braner on 15.11.24.
//

import SwiftUI

let buttonWidth: CGFloat = 100

//
// Content view
//
// Container for drawing view, status view and control view
//
struct ContentView: View {
    @State var resolution = CGSize(width: 800, height: 800)
    @State var oversampling: Int = 1
    @State var redraw: Bool = false
    @State var currentAction: String = ""
    @State var selection = Selection(fromMidPoint: false, keepAspectRatio: true)
    
    var appData: FractalAppData

    var body: some View {

        HStack(spacing: 0) {
            let graphics = ImageGraphics(resolution, oversampling: oversampling)
            
            VStack(spacing: 0) {
                // Create the drawing view
                let drawingCanvas = DrawingView(redraw: $redraw, graphics: graphics, fractal: appData.fractal)

                ScrollView([.horizontal, .vertical], showsIndicators: true) {
                    ZStack {
                        drawingCanvas
                        //DrawingView(graphics: graphics, fractal: fractal)
                        SelectionView(selection: $selection, size: resolution)
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
                .background(.blue)
                
                StatusView(currentAction: $currentAction)
                    .frame(height: 25)
                    .frame(maxWidth: .infinity)
                    .background(.red)
            }
            //Spacer()
            ControlView(resolution: $resolution, oversampling: $oversampling, redraw: $redraw,
                        currentAction: $currentAction, selection: $selection,
                        graphics: graphics, appData: appData)
                .frame(width: appData.controlViewWidth)
                .frame(maxHeight: .infinity)
        }
    }
}




