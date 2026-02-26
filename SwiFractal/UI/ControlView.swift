//
//  ControlView.swift
//  SwiFractal
//
//  Created by Dirk Braner on 11.02.26
//
//  Contains all controls for changing fractal parameters
//

import SwiftUI

//
// Draw methods
//
enum EnumDrawMethod : Int, CaseIterable {
    case sequential
    case parallel
    case metalcompute
    case metalshader
}
typealias DrawMethod = Options<EnumDrawMethod>

//
// Control View
//
struct ControlView: View {
    
    // Bindings
    @Binding var resolution: CGSize
    @Binding var oversampling: Int
    @Binding var redraw: Bool
    @Binding var currentAction: String
    @Binding var selection: Selection
    @Binding var isDrawing: Bool
    @Binding var message: String
    
    // Variables for controlling the behaviour of elements
    @State private var isLightExpanded = false
    @State private var isShadingExpanded = false
    @State private var isStripesStepsExpanded = false
    @State private var isCyclesSamplingExpanded = false
    @State private var isExporting = false
    @State private var isImporting = false
    
    @State var drawMethod: DrawMethod = DrawMethod(.sequential)
    
    @State var linkResolution: Bool = true
    @State var autoIterations: Bool = false
    @State var color: Color = Color.white
    @State var colorTable: String
    
    @State var cornerLeft: String
    @State var cornerBottom: String
    @State var sizeX: String
    @State var sizeY: String
    @State var stripes: Int
    @State var steps: Int
    @State var ncycle: Float
    @State var colorizeMode: ColorizeMode
    @State var colorizeInside: ColorizeInside
    @State var colorizeOutside: ColorizeOutside
    @State var paletteMode: PaletteMode
    @State var angle: Int
    @State var elevation: Int
    @State var opacity: Float
    @State var ambient: Float
    @State var diffuse: Float
    @State var specular: Float
    @State var shininess: Float
    @State var gamma: Float
    @State var iterations: Int

    var ft: String                      // Fractal type
    var graphics: Graphics              // Graphics
    var appData: FractalAppData         // Application data
    
    // Custom initializer
    init(resolution: Binding<CGSize>, oversampling: Binding<Int>, redraw: Binding<Bool>,
         currentAction: Binding<String>, selection: Binding<Selection>, isDrawing: Binding<Bool>,
         message: Binding<String>,
         graphics: Graphics, appData: FractalAppData) {
        self.ft       = appData.fractal.fractalType
        self.graphics = graphics
        self.appData  = appData
        
        // Initialize bindings
        _resolution    = resolution
        _oversampling  = oversampling
        _redraw        = redraw
        _currentAction = currentAction
        _selection     = selection
        _isDrawing     = isDrawing
        _message       = message
        
        // Initialize State variables from application settings
        _cornerLeft   = State(initialValue: appData.fractal.settings["cornerLeft"])
        _cornerBottom = State(initialValue: appData.fractal.settings["cornerBottom"])
        _sizeX        = State(initialValue: appData.fractal.settings["sizeX"])
        _sizeY        = State(initialValue: appData.fractal.settings["sizeY"])
        _stripes      = State(initialValue: appData.fractal.settings["\(ft).stripes"])
        _steps        = State(initialValue: appData.fractal.settings["\(ft).steps"])
        _ncycle       = State(initialValue: appData.fractal.settings["\(ft).ncycle"])
        _colorTable  = State(initialValue: appData.fractal.settings["\(ft).colorTable"])
        _colorizeMode    = State(initialValue: appData.fractal.settings["\(ft).colorizeMode"])
        _colorizeInside  = State(initialValue: appData.fractal.settings["\(ft).colorizeInside"])
        _colorizeOutside = State(initialValue: appData.fractal.settings["\(ft).colorizeOutside"])
        _paletteMode     = State(initialValue: appData.fractal.settings["\(ft).paletteMode"])
        _angle        = State(initialValue: appData.fractal.settings["lightning.angle"])
        _elevation    = State(initialValue: appData.fractal.settings["lightning.elevation"])
        _opacity      = State(initialValue: appData.fractal.settings["lightning.opacity"])
        _ambient      = State(initialValue: appData.fractal.settings["lightning.ambient"])
        _diffuse      = State(initialValue: appData.fractal.settings["lightning.diffuse"])
        _specular     = State(initialValue: appData.fractal.settings["lightning.specular"])
        _shininess    = State(initialValue: appData.fractal.settings["lightning.shininess"])
        _gamma        = State(initialValue: appData.fractal.settings["lightning.gamma"])
        _iterations   = State(initialValue: appData.fractal.settings["\(ft).iterations"])
    }

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
                                    cornerLeft   = String(newCorner.real)
                                    cornerBottom = String(newCorner.imaginary)
                                    sizeX        = String(newSize.real)
                                    sizeY        = String(newSize.imaginary)
                                    appData.fractal.settings["cornerLeft"]   = cornerLeft
                                    appData.fractal.settings["cornerBottom"] = cornerBottom
                                    appData.fractal.settings["sizeX"]        = sizeX
                                    appData.fractal.settings["sizeY"]        = sizeY
                                    if autoIterations {
                                        iterations = appData.fractal.maxIterationCount
                                        appData.fractal.settings["\(ft).iterations"] = iterations
                                    }
                                }
                            }
                            Button("Draw") {
                                Task {
                                    if (await graphics.beginDraw {
                                        currentAction = "Drawing ..."
                                        message = ""
                                        isDrawing = true
                                        appData.fractal.draw(graphics, drawMethod)
                                        isDrawing = false
                                    }) {
                                        graphics.endDraw()
                                        currentAction = "Done."
                                        message = "Calculation time: \(appData.fractal.formattedCalculationTime)"
                                        selection.reset()
                                        redraw.toggle()
                                    }
                                }
                            }.disabled(isDrawing)
                        }
                        HStack(spacing: 5) {
                            // Den Export-Button einfach aufrufen
                            ExportButton(document: FractalDocument(data: appData.fractal.settings))
                            
                            // Den Import-Button aufrufen und das Ergebnis empfangen
                            ImportButton { decodedData in
                                appData.fractal.settings = decodedData
                            }
                        }
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
                        /*
                        LabeledInputField("Left", $cornerLeft, width: 170)
                            .onValueChanged { v in
                                appData.fractal.settings["cornerLeft"] = v
                            }
                         */
                        LabeledInputField("Left", Binding(
                            get: { appData.fractal.settings["cornerLeft", default: "-2.25"] },
                            set: { appData.fractal.settings["cornerLeft"] = $0 }
                        ), width: 170)
                        LabeledInputField("Bottom", $cornerBottom, width: 170)
                            .onValueChanged { v in
                                appData.fractal.settings["cornerBottom"] = v
                            }
                        LabeledInputField("Size X", $sizeX, width: 170)
                            .onValueChanged { v in
                                appData.fractal.settings["sizeX"] = v
                            }
                        LabeledInputField("Size Y", $sizeY, width: 170)
                            .onValueChanged { v in
                                appData.fractal.settings["sizeY"] = v
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
                            Picker(selection: $colorTable, label: Text("")) {
                                ForEach(FractalAppData.colorTables.keys.sorted(), id: \.self) { key in
                                    ColorPalette(colorTable: FractalAppData.colorTables[key]!,
                                                 size: CGSize(width: 150, height: 20), label: key)
                                    .tag(key)
                                }
                            }
                            .onChange(of: colorTable) {
                                appData.fractal.settings["\(ft).colorTable"] = colorTable
                            }
                        }
                        OptionsPicker(options: $colorizeMode, "Mode")
                            .onValueChanged { v in appData.fractal.settings["\(ft).colorizeMode"] = v }
                            .padding([.top], 10)
                        OptionsPicker(options: $colorizeInside, "Inside")
                            .onValueChanged { v in appData.fractal.settings["\(ft).colorizeInside"] = v }
                            .padding([.top], 10)
                        if colorizeMode == ColorizeMode(.iterations) {
                            OptionsPicker(options: $paletteMode, "Mapping")
                                .onValueChanged { v in appData.fractal.settings["\(ft).paletteMode"] = v}
                                .padding([.top], 10)
                        }
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
                            Toggle(isOn: $autoIterations) { Text("Auto iterations") }
                                .onChange(of: autoIterations) { oldValue, newValue in
                                    iterations = newValue ? appData.fractal.maxIterationCount : appData.fractal.settings["\(ft).iterations"]
                                    print("iterations: \(iterations) \(autoIterations) \(appData.fractal.maxIterationCount)")
                                }
                            LabeledStepper<Int>("Iterations:", $iterations, range: 0...4096, step: 50)
                                .onValueChanged { v in appData.fractal.settings["\(ft).iterations"] = v }
                                .disabled(autoIterations)
                        }
                    }.padding([.top], 10)
                }
                Spacer()
            }.padding(10)
        }
    }
    
}
