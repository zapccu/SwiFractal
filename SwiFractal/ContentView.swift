//
//  ContentView.swift
//  SwiFractal
//
//  Created by Dirk Braner on 15.11.24.
//

import SwiftUI

//
// Selection View
//
// Shown on top of the drawing view for interactively selecting a view area
//
struct SelectionView: View {
    @State var selection = Selection(fromMidPoint: true)
    var size: CGSize

    private func handleSelection() -> some Gesture {
        return DragGesture(minimumDistance: 0)
            .onChanged { event in
                selection.onChanged(event, CGRect(origin: .zero, size: size))
            }
            .onEnded{ event in
                selection.onEnded(event, CGRect(origin: .zero, size: size))
            }
    }

    var body: some View {
        Canvas { context, size in
            let graphics = CGGraphics(context, size)
            selection.draw(graphics)
        }
        .gesture(handleSelection())
    }
}

//
// Drawing View
//
// Contains the fractal graphic
//
struct DrawingView: View {
    @Binding var redraw: Bool
    
    var graphics: ImageGraphics
    var fractal: Mandelbrot
    
    var body: some View {
        Canvas(rendersAsynchronously: false) { context, size in
            print("redraw: \(redraw), fractal.redraw: \(fractal.redraw)")

            if fractal.redraw {
                if (graphics.beginDraw {
                    graphics.clear(.black)
                    fractal.beginCalculation()
#if DEBUG
                    print("Debug: Rendering Mandelbrot, size: \(size)")
                    fractal.calculate(graphics)
#else
                    print("Release: Rendering Mandelbrot parallel, size: \(size)")
                    fractal.calculatePar(graphics)
                    // fractal.render(graphics)
#endif
                    fractal.endCalculation()
                    graphics.drawImage(context)
                }) {
                    let drawTime = graphics.endDraw()
                    print("drawTime: \(drawTime)")
                    fractal.redraw = false
                }
                fractal.redraw = false
            }
            else {
                graphics.drawImage(context)
            }
        }
        .frame(width: graphics.size.width, height: graphics.size.height, alignment: .topLeading)
        .task {
            if fractal.redraw {
                
            }
        }
    }

}

//
// Control view
//
// Contains all controls for changing fractal parameters
//
struct ControlView: View {
    @Binding var resolution: CGSize
    @Binding var redraw: Bool
    @Binding var currentAction: String
    
    @State var linkResolution: Bool = true
    
    @State var corner: String = ""
    @State var size: String = ""
    @State var stripes: Float = 0
    @State var steps: Float = 0
    @State var cycles: Float = 1.0
    @State var oversampling = 1.0
    @State var iterations: Int = 100

    var fractal: Mandelbrot
    
    var body: some View {
        Grid {
            GridRow {
                Button("Draw") {
                    currentAction = "Drawing ..."
                    print("Corner is \(corner)")
                    fractal.redraw = true
                    redraw.toggle()
                }
                Button("Reset") {
                    
                }
                Button("Export") {
                    /*
                     let renderer = ImageRenderer(content: drawingCanvas)
                     let image = renderer.nsImage
                     if !Graphics.saveNSImage(image: image!, path: "/Users/dirk/Pictures/swiFractalns.png") {
                     print("Error write NSImage to file")
                     }
                     */
                }
            }
            GroupBox(label: Text("Resolution").font(.system(size: 12))) {
                Grid(alignment: .leading) {
                    GridRow {
                        Toggle(isOn: $linkResolution) { Text("Keep aspect ratio") }
                    }
                    GridRow {
                        Stepper("\(resolution.width.formatted()) px", value: $resolution.width, in: 100...4096, step: 50) { actionInProgress in
                            if linkResolution { resolution.height = resolution.width }
                        }
                        Stepper("\(resolution.height.formatted()) px", value: $resolution.height, in: 100...4096, step: 50) { actionInProgress in
                            if linkResolution { resolution.width = resolution.height }
                        }
                    }
                    Divider().hidden()
                }
            }
            GroupBox(label: Text("Fractal dimensions")) {
                Grid(alignment: .leading) {
                    GridRow {
                        Text("Complex corner:")
                        TextField("Corner", text: $corner)
                            .onAppear() { corner = String(fractal.settings["corner"] as Cplx) }
                    }
                    GridRow {
                        Text("Complex size:")
                        TextField("Size", text: $size)
                            .onAppear() { size = String(fractal.settings["size"] as Cplx) }
                    }
                }
            }
            GroupBox(label: Text("Drawing options")) {
                Grid(alignment: .leading) {
                    GridRow {
                        Text("Stripes:")
                        Slider(value: $stripes, in: 0...32)
                        Text("\(Int(stripes))")
                    }
                    GridRow {
                        Text("Steps:")
                        Slider(value: $steps, in: 0...100)
                        Text("\(Int(steps))")
                    }
                    GridRow {
                        Text("Cycles:")
                        Slider(value: $cycles, in: 1...200)
                        Text("\(Int(cycles))")
                    }
                    GridRow {
                        Text("Oversampling:")
                        Slider(value: $oversampling, in: 1...3)
                        Text("\(Int(oversampling))")
                    }
                }
            }
            GroupBox(label: Text("Light")) {
                Grid(alignment: .leading) {
                    GridRow {
                        Text("Angle:")
                        Text("Elevation:")
                    }
                }
            }
            if fractal.fractalType == "Mandelbrot" {
                GroupBox(label: Text("Mandelbrot Set")) {
                    Grid(alignment: .leading) {
                        GridRow {
                            Stepper("\(iterations)", value: $iterations, in: 100...4096, step: 50)
                                .onAppear() { iterations = fractal.settings["iterations"] as Int }
                        }
                    }
                }
            }
            Spacer()
        }.padding()
    }
}

//
// Status view
//
// Used for showing status information on bottom of window
//
struct StatusView: View {
    @Binding var currentAction: String

    var resolution: CGSize
    var height = CGFloat(30)
    
    var body: some View {
        HStack {
            Text(currentAction).frame(width: 100, height: height)
            Text("Field 2").frame(width: 150, height: height)
            Spacer()
        }
        .frame(width: resolution.width, height: height)
        .background(.gray)
    }
}

//
// Content view
//
// Container for drawing view, status view and control view
//
struct ContentView: View {
    @State var resolution = CGSize(width: 800, height: 800)
    @State var redraw: Bool = false
    @State var currentAction: String = ""
    
    var fractal: Mandelbrot

    var body: some View {
        // Create the drawing view
        let graphics = ImageGraphics(resolution)
        let drawingCanvas = DrawingView(redraw: $redraw, graphics: graphics, fractal: fractal)
        
        HStack {
            VStack {
                ScrollView([.horizontal, .vertical], showsIndicators: true) {
                    ZStack {
                        drawingCanvas
                        SelectionView(size: resolution)
                    }
                }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                Spacer()
                StatusView(currentAction: $currentAction, resolution: resolution, height: 25)
            }
            Spacer()
            ControlView(resolution: $resolution, redraw: $redraw, currentAction: $currentAction,
                        fractal: fractal)
        }
    }
}




