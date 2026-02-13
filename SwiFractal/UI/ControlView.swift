//
//  ControlView.swift
//  SwiFractal
//
//  Created by Dirk Braner on 11.02.26
//
//  Contains all controls for changing fractal parameters
//

import SwiftUI

enum EnumDrawMethod : Int, CaseIterable {
    case sequential
    case parallel
    case metalcompute
    case metalshader
}

typealias DrawMethod = Options<EnumDrawMethod>

struct ControlView: View {
    @Binding var resolution: CGSize
    @Binding var oversampling: Int
    @Binding var redraw: Bool
    @Binding var currentAction: String
    @Binding var selection: Selection
    
    @State private var isLightExpanded = false
    @State private var isShadingExpanded = false
    @State private var isStripesStepsExpanded = false
    @State private var isCyclesSamplingExpanded = false
    
    @State var drawMethod: DrawMethod = DrawMethod(.sequential)
    
    @State var linkResolution: Bool = true
    @State var color: Color = Color.white
    @State var colorTableName: String = "Grey"
    
    @State var corner: Cplx = Cplx(-2.0, -1.5)
    @State var size: Cplx = Cplx(3.0, 3.0)
    @State var stripes: Int = 0
    @State var steps: Int = 0
    @State var ncycle: Int = 1
    @State var colorizeInside = ColorizeInside(.simple)
    @State var colorizeOutside = ColorizeOutside(.simple)
    @State var paletteMode = PaletteMode(.linear)
    @State var angle: Int = 45
    @State var elevation: Int = 45
    @State var opacity: Float = 0.75
    @State var ambient: Float = 0.2
    @State var diffuse: Float = 0.5
    @State var specular: Float = 0.5
    @State var shininess: Float = 20.0
    @State var gamma: Float = 1.0
    @State var iterations: Int = 100

    var graphics: Graphics              // Graphics
    var appData: FractalAppData
        
    var body: some View {
        let ft = appData.fractal.fractalType
        
        ScrollView([.vertical]) {
            VStack(alignment: .leading) {
                
                //
                // Buttons
                //
                
                GroupBox(label: Text("Actions").foregroundStyle(.blue).font(.headline))  {
                    VStack(alignment: .leading) {
                        HStack(spacing: 5) {
                            Button("Apply") {
                                if selection.state == .areaSelected {
                                    let area = selection.getArea(flipped: true, height: graphics.height)
                                    let (newCorner, newSize) = appData.fractal.zoomArea(area, graphics.width, graphics.height)
                                    appData.fractal.settings["corner"] = newCorner
                                    appData.fractal.settings["size"]   = newSize
                                    corner = appData.fractal.settings["corner"]
                                    size   = appData.fractal.settings["size"]
                                }
                            }
                            Button("Draw") {
                                if (graphics.beginDraw {
                                    graphics.clear(color: .blue)
                                    appData.fractal.beginCalculation(graphics.width, graphics.height)
                                    
                                    print("Rendering Mandelbrot with method \(drawMethod.name)")
                                    switch drawMethod.element {
                                    case .sequential:
                                        appData.fractal.calculateLineByLine(graphics)
                                    case .parallel:
                                        appData.fractal.calculateParallel(graphics)
                                    case .metalcompute:
                                        appData.fractal.calculateMetal(graphics)
                                    case .metalshader:
                                        break
                                    default:
                                        break
                                    }
                                    
                                    appData.fractal.endCalculation()
                                    print("calculation time: \(appData.fractal.calculationTime)")
                                }) {
                                    let drawTime = graphics.endDraw()
                                    print("drawTime: \(drawTime)")
                                    selection.reset()
                                    redraw.toggle()
                                }
                            }
                            Button("Export") {
                                dump(appData.fractal.settings)
                                /*
                                 let renderer = ImageRenderer(content: drawingCanvas)
                                 let image = renderer.nsImage
                                 if !Graphics.saveNSImage(image: image!, path: "/Users/dirk/Pictures/swiFractalns.png") {
                                 print("Error write NSImage to file")
                                 }
                                 */
                            }
                            Spacer()
                        }.frame(alignment: .leading)
                    }
                }.padding([.top], 10)
                
                //
                // Dimensions, Aspect ratio
                //
                
                GroupBox(label: Text("Resolution").foregroundStyle(.blue).font(.headline)) {
                    VStack(alignment: .leading) {
                        HStack(spacing: 20) {
                            Stepper("\(resolution.width.formatted()) px", value: $resolution.width, in: 100...4096, step: 50) { actionInProgress in
                                if linkResolution { resolution.height = resolution.width }
                            }
                            Stepper("\(resolution.height.formatted()) px", value: $resolution.height, in: 100...4096, step: 50) { actionInProgress in
                                if linkResolution { resolution.width = resolution.height }
                            }
                            Spacer()
                        }.frame(alignment: .leading)
                        Toggle(isOn: $linkResolution) { Text("Aspect ratio") }
                        OptionsPicker(options: $drawMethod, "Method")
                    }
                }.padding([.top], 10)
                
                GroupBox(label: Text("Fractal dimensions").foregroundStyle(.blue).font(.headline)) {
                    VStack(alignment: .leading) {
                        LabeledInputField("Corner real", $corner.real, width: 150)
                            .onValueChanged { v in
                                let c: Cplx = appData.fractal.settings["corner"]
                                appData.fractal.settings["corner"] = Cplx(v, c.imaginary)
                            }
                        LabeledInputField("Corner imag", $corner.imaginary, width: 150)
                            .onValueChanged { v in
                                let c: Cplx = appData.fractal.settings["corner"]
                                appData.fractal.settings["corner"] = Cplx(c.real, v)
                            }
                        LabeledInputField("Size real", $size.real, width: 150)
                            .onValueChanged { v in
                                let s: Cplx = appData.fractal.settings["size"]
                                appData.fractal.settings["size"] = Cplx(v, s.imaginary)
                            }
                        LabeledInputField("Size imag", $size.imaginary, width: 150)
                            .onValueChanged { v in
                                let s: Cplx = appData.fractal.settings["size"]
                                appData.fractal.settings["size"] = Cplx(s.real, v)
                            }
                    }
                }.padding([.top], 10)
                
                GroupBox(label: Text("Drawing options").foregroundStyle(.blue).font(.headline)) {
                    DisclosureGroup("Stripes & Steps", isExpanded: $isStripesStepsExpanded) {
                        VStack(alignment: .leading) {
                            LabeledStepper("Stripes", $stripes, range: 0...32)
                                .onValueChanged { v in appData.fractal.settings["\(ft).stripes"] = v }
                            LabeledStepper("Steps", $steps, range: 0...100)
                                .onValueChanged { v in appData.fractal.settings["\(ft).steps"] = v }
                        }
                    }
                    DisclosureGroup("Cycles & Sampling", isExpanded: $isCyclesSamplingExpanded) {
                        VStack(alignment: .leading) {
                            LabeledStepper("Cycles:", $ncycle, range: 1...200)
                                .onValueChanged { v in appData.fractal.settings["\(ft).ncycle"] = v }
                            LabeledStepper("Sampling:", $oversampling, range: 1...3)
                                .onValueChanged { v in appData.fractal.settings["oversampling"] = v }
                        }
                    }
                }.padding([.top], 10)
                
                //
                // Coloring
                //
                
                GroupBox(label: Text("Coloring").foregroundStyle(.blue).font(.headline)) {
                    VStack(alignment: .leading) {
                        HStack(spacing: 10) {
                            Text("Color palette")
                        }
                        HStack(spacing: 10) {
                            Picker(selection: $colorTableName, label: Text("")) {
                                ForEach(FractalAppData.colorTables.keys.sorted(), id: \.self) { key in
                                    ColorPalette(colorTable: FractalAppData.colorTables[key]!, size: CGSize(width: 150, height: 20), label: key).tag(key)
                                }
                            }
                            //.fixedSize()
                            .onChange(of: colorTableName) {
                                appData.fractal.settings["\(ft).colorTable"] = colorTableName
                            }
                            .onAppear {
                                colorTableName = appData.fractal.settings["\(ft).colorTable"]
                            }
                        }
                        OptionsPicker(options: $colorizeInside, "Inside")
                            .onValueChanged { v in appData.fractal.settings["\(ft).colorizeInside"] = v }
                            .padding([.top], 10)
                        OptionsPicker(options: $paletteMode, "Palettemode")
                            .onValueChanged { v in appData.fractal.settings["\(ft).paletteMode"] = v}
                            .padding([.top], 10)
                        //Divider().hidden()
                    }
                }.padding([.top], 10)
                
                //
                // Light and shading
                //
                
                GroupBox(label: Text("Light and shading").foregroundStyle(.blue).font(.headline)) {
                    VStack(alignment: .leading, spacing: 10) {
                        GroupBox {
                            DisclosureGroup("Shading", isExpanded: $isShadingExpanded) {
                                VStack(alignment: .leading, spacing: 8) {
                                    OptionsPicker(options: $colorizeOutside, "Outside")
                                        .onValueChanged { v in appData.fractal.settings["\(ft).colorizeOutside"] = v }
                                        .padding([.top], 10)
                                    LabeledStepper("Angle:", $angle, range: 0...360, step: 5, unit: "°")
                                        .onValueChanged { v in appData.fractal.settings["lightning.angle"] = v }
                                    LabeledStepper("Elevation:", $elevation, range: 0...90,  step: 5, unit: "°")
                                        .onValueChanged { v in appData.fractal.settings["lightning.elevation"] = v }
                                }
                            }
                        }
                        GroupBox {
                            DisclosureGroup("Light", isExpanded: $isLightExpanded) {
                                VStack(alignment: .leading, spacing: 8) {
                                    LabeledSlider("Opacity:", $opacity, range: 0.0...1.0, step: 0.1, width: 100, format: "%.1f")
                                        .onValueChanged { v in appData.fractal.settings["lightning.opacity"] = v }
                                    LabeledSlider("Ambient:", $ambient, range: 0.0...1.0, step: 0.05, width: 100, format: "%.2f")
                                        .onValueChanged { v in appData.fractal.settings["lightning.ambient"] = v }
                                    LabeledSlider("Diffuse:", $diffuse, range: 0.0...1.0, step: 0.05, width: 100, format: "%.2f")
                                        .onValueChanged { v in appData.fractal.settings["lightning.diffuse"] = v }
                                    LabeledSlider("Specular:",$specular, range: 0.0...1.0, step: 0.05, width: 100, format: "%.2f")
                                        .onValueChanged { v in appData.fractal.settings["lightning.specular"] = v }
                                    LabeledSlider("Shininess:", $shininess, range: 1.0...30.0, step: 1.0, width: 100, format: "%2.0f")
                                        .onValueChanged { v in appData.fractal.settings["lightning.shininess"] = v }
                                    LabeledSlider("Gamma:", $gamma, range: 0.1...9.9, step: 0.1, width: 100, format: "%.1f")
                                        .onValueChanged { v in appData.fractal.settings["lightning.gamma"] = v }
                                }
                            }
                        }
                    }
                }.padding([.top], 10)
                
                //
                // Parameters depending on fractal type
                //
                
                if ft == "Mandelbrot" {
                    GroupBox(label: Text("Mandelbrot Set").foregroundStyle(.blue).font(.headline)) {
                        VStack(alignment: .leading) {
                            LabeledStepper("Iterations:", $iterations, range: 0...4096, step: 50)
                                .onValueChanged { v in appData.fractal.settings["\(ft).iterations"] = v }
                        }
                    }.padding([.top], 10)
                }
                Spacer()
            }.padding(10)
        }
    }
    
}
