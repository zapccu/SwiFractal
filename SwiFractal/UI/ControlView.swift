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
// Control View
//
struct ControlView: View {
    
    // Bindings
    @Binding var resolution: CGSize
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
    
    @State var drawMethod: DrawMethod = .sequential
    
    @State var linkResolution: Bool = true
    @State var autoIterations: Bool = false
    @State var color: Color = Color.white
    @State var colorTable: String
    
    var ft: String                      // Fractal type
    var graphics: Graphics              // Graphics
    var fractal: Fractal         // Application data
    
    // Custom initializer
    init(resolution: Binding<CGSize>, redraw: Binding<Bool>, currentAction: Binding<String>,
         selection: Binding<Selection>, isDrawing: Binding<Bool>, message: Binding<String>,
         graphics: Graphics, fractal: Fractal) {
        self.ft       = fractal.fractalType
        self.graphics = graphics
        self.fractal  = fractal
        
        // Initialize bindings
        _resolution    = resolution
        _redraw        = redraw
        _currentAction = currentAction
        _selection     = selection
        _isDrawing     = isDrawing
        _message       = message
        
        // Initialize State variables from application settings
        _colorTable  = State(initialValue: fractal.settings["\(ft).colorTable"])
    }

    var body: some View {
        let ft = fractal.fractalType
        
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
                                    let (newCorner, newSize) = fractal.zoomArea(area, graphics.width, graphics.height)
                                    fractal.settings.updateSettings([
                                        "cornerLeft": String(newCorner.real),
                                        "cornerBottom": String(newCorner.imaginary),
                                        "sizeX": String(newSize.real),
                                        "sizeY": String(newSize.imaginary)
                                    ])
                                    if let M = fractal as? Mandelbrot, autoIterations {
                                        fractal.settings["\(ft).iterations"] = M.maxIterationCount
                                    }
                                }
                            }
                            Button("Draw") {
                                Task {
                                    if (await graphics.beginDraw {
                                        currentAction = "Drawing ..."
                                        message = ""
                                        isDrawing = true
                                        fractal.draw(graphics, drawMethod)
                                        isDrawing = false
                                    }) {
                                        graphics.endDraw()
                                        currentAction = "Done."
                                        message = "Calculation time: \(fractal.formattedCalculationTime)"
                                        selection.reset()
                                        redraw.toggle()
                                    }
                                }
                            }.disabled(isDrawing)
                            Button("Reset") {
                                fractal.resetSettings()
                            }
                        }
                        HStack(spacing: 5) {
                            // Den Export-Button einfach aufrufen
                            ExportButton(document: FractalDocument(data: fractal.settings))
                            
                            // Den Import-Button aufrufen und das Ergebnis empfangen
                            ImportButton { decodedData in
                                fractal.settings = decodedData
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
                        LabeledPicker(label: "Method", selection: $drawMethod)
                    }
                }.padding([.top], 10)
                
                GroupBox(label: Text("Fractal dimensions").foregroundStyle(.blue).font(.headline)) {
                    VStack(alignment: .leading) {
                        LabeledInputField("Left", binding(for: "cornerLeft", defval: "-2.25"), width: 170)
                        LabeledInputField("Bottom", binding(for: "cornerBottom", defval: "-1.5"), width: 170)
                        LabeledInputField("Size X", binding(for: "sizeX", defval: "3.0"), width: 170)
                        LabeledInputField("Size Y", binding(for: "sizeY", defval: "3.0"), width: 170)
                    }
                }.padding([.top], 10)
                
                GroupBox(label: Text("Drawing options").foregroundStyle(.blue).font(.headline)) {
                    DisclosureGroup("Stripes & Steps", isExpanded: $isStripesStepsExpanded) {
                        VStack(alignment: .leading) {
                            LabeledStepper("Stripes", binding(for: "stripes", defval: 0), range: 0...32)
                            LabeledStepper("Steps", binding(for: "\(ft).steps", defval: 0), range: 0...100)
                        }
                    }
                    DisclosureGroup("Cycles & Sampling", isExpanded: $isCyclesSamplingExpanded) {
                        VStack(alignment: .leading) {
                            LabeledStepper("Cycles:", binding(for: "\(ft).ncycle", defval: 1.0), range: 1...200)
                            LabeledStepper("Sampling:", binding(for: "oversampling", defval: 1), range: 1...3)
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
                                ForEach(ColorMapping.colorTables.keys.sorted(), id: \.self) { key in
                                    ColorPalette(colorTable: ColorMapping.colorTables[key]!,
                                                 size: CGSize(width: 150, height: 20), label: key)
                                    .tag(key)
                                }
                            }
                            .onChange(of: colorTable) {
                                fractal.settings["\(ft).colorTable"] = colorTable
                            }
                        }
                        OptionsPicker(options: binding(for: "\(ft).colorizeMode", defval: ColorizeMode(.iterations)), "Mode")
                            .padding([.top], 10)
                        OptionsPicker(options: binding(for: "\(ft).colorizeInside", defval: ColorizeInside(.simple)), "Inside")
                            .padding([.top], 10)
                        if colorizeMode == ColorizeMode(.iterations) {
                            OptionsPicker(options: binding(for: "\(ft).paletteMode", defval: PaletteMode(.linear)), "Mapping")
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
                                    OptionsPicker(options: binding(for: "\(ft).colorizeOutside", defval: ColorizeOutside(.simple)), "Outside")
                                        .padding([.top], 10)
                                    LabeledStepper("Angle:", binding(for: "lightning.angle", defval: 45), range: 0...360, step: 5, unit: "°")
                                    LabeledStepper("Elevation:", binding(for: "lightning.elevation", defval: 45), range: 0...90,  step: 5, unit: "°")
                                }
                            }
                        }
                        GroupBox {
                            DisclosureGroup("Light", isExpanded: $isLightExpanded) {
                                VStack(alignment: .leading, spacing: 8) {
                                    LabeledSlider("Opacity:", binding(for: "lightning.opacity", defval: 0.75), range: 0.0...1.0, step: 0.1, width: 100, format: "%.1f")
                                    LabeledSlider("Ambient:", binding(for: "lightning.ambient", defval: 0.2), range: 0.0...1.0, step: 0.05, width: 100, format: "%.2f")
                                    LabeledSlider("Diffuse:", binding(for: "lightning.diffuse", defval: 0.5), range: 0.0...1.0, step: 0.05, width: 100, format: "%.2f")
                                    LabeledSlider("Specular:",binding(for: "lightning.specular", defval: 0.5), range: 0.0...1.0, step: 0.05, width: 100, format: "%.2f")
                                    LabeledSlider("Shininess:", binding(for: "lightning.shininess", defval: 20.0), range: 1.0...30.0, step: 1.0, width: 100, format: "%2.0f")
                                    LabeledSlider("Gamma:", binding(for: "lightning.gamma", defval: 1.0), range: 0.1...9.9, step: 0.1, width: 100, format: "%.1f")
                                }
                            }
                        }
                    }
                }.padding([.top], 10)
                
                //
                // Parameters depending on fractal type
                //
                
                if let M = fractal as? Mandelbrot {
                    GroupBox(label: Text("Mandelbrot Set").foregroundStyle(.blue).font(.headline)) {
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle(isOn: $autoIterations) { Text("Auto iterations") }
                                .onChange(of: autoIterations) { oldValue, newValue in
                                    if newValue {
                                        fractal.settings["\(ft).iterations"] = M.maxIterationCount
                                    }
                                }
                            LabeledStepper("Iterations:", binding(for: "\(ft).iterations", defval: 200), range: 0...4096, step: 50)
                                .disabled(autoIterations)
                        }
                    }.padding([.top], 10)
                }
                Spacer()
            }.padding(10)
        }
    }
    
}

//
// Simplify access to bindings
//

extension ControlView {
    
    func binding<T>(for key: String, defval: T) -> Binding<T> where T: Castable {
        Binding(
            get: { fractal.settings[key, default: defval ] },
            set: {
                guard fractal.settings.valExists(key) else {
                    #if DEBUG
                    print("binding: key \(key) not found")
                    #endif
                    return
                }
                fractal.settings[key] = $0
            }
        )
    }
    
}
