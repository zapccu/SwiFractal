//
//  ControlParameterView.swift
//  SwiFractal
//
//  Created by Dirk Braner on 05.08.26.
//

import SwiftUI
import SwiftMPx
import ParSetKit

struct ControlParameterView<T: FractalProtocol & Observable>: View {

    typealias RT = T.RT
    
    let controller: FractalController
    var fractal: T

    /// Binding for FractalController
    var bController: Bindable<FractalController> {
        Bindable(controller)
    }
    
    /// Binding for Fractal
    var bFractal: Bindable<T> {
        Bindable(fractal)
    }
    
    // Flags for expanding control groups
    @State private var isLightExpanded = false
    @State private var isShadingExpanded = false
    @State private var isStripesStepsExpanded = false
    @State private var isColorChangingExpanded = false
    
    @State private var autoIterations: Bool = false
    //@State private var coloringName: String = FractalAppData.defaultColoring

    var body: some View {

        //
        // Common information
        //
        GroupBox(label: Text("Info").foregroundStyle(.blue).font(.headline)) {
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                GridRow {
                    Text("Name")
                    TextField("", text: bFractal.FP.name)
                }
            }.padding(.horizontal, 5)
        }.padding([.top], 10)
        
        //
        // Fractal dimensions and oversampling
        //
        GroupBox(label: Text("Fractal dimensions").foregroundStyle(.blue).font(.headline)) {
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                GridRow {
                    Text("Left")
                    TextField("", text: bController.dimensions.strDimensions.cornerX)
                }
                GridRow {
                    Text("Bottom")
                    TextField("", text: bController.dimensions.strDimensions.cornerY)
                }
                GridRow {
                    Text("Size X")
                    TextField("", text: bController.dimensions.strDimensions.sizeX)
                }
                GridRow {
                    Text("Size Y")
                    TextField("", text: bController.dimensions.strDimensions.sizeY)
                }
                GridRow {
                    Text("Sampling")
                    Stepper("\(controller.dimensions.oversampling)", value: bController.dimensions.oversampling, in: 1...3, step: 1)
                        .padding(.leading, 7)
                }
                GridRow {
                    let dimensions = fractal.FP.dimensions
                    Text("Rendering")
                    Text("\(dimensions.renderPrecision.rawValue) (\(dimensions.precision.bits.description) bits)")
                }
            }.padding(.horizontal, 5)
        }.padding([.top], 10)
        
        //
        // Julia point
        //
        if let j = fractal as? Julia<RT> {
            JuliaParView(fractal: j)
        }
        
        //
        // Coloring
        //
        GroupBox(label: Text("Coloring").foregroundStyle(.blue).font(.headline)) {
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                GridRow {
                    //Text("Colors")
                    Picker(selection: bFractal.FP.colorParameters.coloringName, label: Text("")) {
                        ForEach(FractalAppData.colorings.keys.sorted(), id: \.self) { key in
                            ColoringView(
                                coloring: FractalAppData.colorings[key]!,
                                size: CGSize(width: 100, height: 20),
                                label: key
                            )
                            .tag(key)
                        }
                    }.onAppear {
                        // Add Coloring to FractalAppData.colorings
                        if FractalAppData.colorings.index(forKey: fractal.FP.colorParameters.coloringName) == nil {
                            let name = fractal.FP.colorParameters.coloringName
                            FractalAppData.addColoring(coloring: fractal.FP.colorParameters.coloring, name: name)
                        }
                    }.onChange(of: fractal.FP.colorParameters.coloringName) { _, newValue in
                        if let coloring = FractalAppData.colorings[newValue] {
                            fractal.FP.colorParameters.coloring = coloring
                            Task { await controller.drawResultSet() }
                        }
                        else {
                            debugPrint("Coloring \(newValue) not found")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .gridCellColumns(2)
                }
                GridRow {
                    Text("Mode")
                    OptionsPicker(options: bFractal.FP.colorParameters.colorizeMode, width: 140)
                        .onChange(of: fractal.FP.colorParameters.colorizeMode) { _, newValue in
                            if newValue == .stripes && fractal.FP.colorParameters.stripes == 0 { fractal.FP.colorParameters.stripes = 1 }
                            if newValue == .steps && fractal.FP.colorParameters.steps == 0 { fractal.FP.colorParameters.steps = 1 }
                        }
                }
                GridRow {
                    Text("Inside")
                    OptionsPicker(options: bFractal.FP.colorParameters.colorizeInside, width: 140)
                        .onChange(of: fractal.FP.colorParameters.colorizeInside) {
                            Task { await controller.drawResultSet() }
                        }
                }
                GridRow {
                    Text("Outside")
                    OptionsPicker(options: bFractal.FP.colorParameters.colorizeOutside, width: 140)
                        .onChange(of: fractal.FP.colorParameters.colorizeOutside) {
                            Task { await controller.drawResultSet() }
                        }
                }
                if fractal.FP.colorParameters.colorizeMode == ColorizeMode(.iterations) {
                    GridRow {
                        Text("Mapping")
                        OptionsPicker(options: bFractal.FP.colorParameters.paletteMode, width: 140)
                            .onChange(of: fractal.FP.colorParameters.paletteMode) {
                                Task { await controller.drawResultSet() }
                            }
                    }
                }
            }.padding(.horizontal, 5)
        }.padding([.top], 10)
        
        //
        // Light and shading
        //
        GroupBox(label: Text("Light and shading").foregroundStyle(.blue).font(.headline)) {
            VStack(alignment: .leading, spacing: 10) {
                GroupBox {
                    DisclosureGroup("Shading", isExpanded: $isShadingExpanded) {
                        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                            GridRow {
                                Text("Angle")
                                LinearStepper(value: bFractal.FP.lightParameters.angle, unit: "°", range: 0...360, step: 5)
                                Spacer()
                            }
                            GridRow {
                                Text("Elevation")
                                LinearStepper(value: bFractal.FP.lightParameters.elevation, unit: "°", range: 0...90, step: 5)
                                Spacer()
                            }
                        }.padding([.top, .bottom, .horizontal], 5)
                    }
                }
                GroupBox {
                    DisclosureGroup("Light", isExpanded: $isLightExpanded) {
                        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                            GridRow {
                                Text("Opacity")
                                LinearSlider(value: bFractal.FP.lightParameters.opacity, range: 0.0...1.0, step: 0.1, format: "%.1f", width: 120)
                            }
                            GridRow {
                                Text("Ambient")
                                LinearSlider(value: bFractal.FP.lightParameters.ambient, range: 0.0...1.0, step: 0.05, format: "%.2f", width: 120)
                            }
                            GridRow {
                                Text("Diffuse")
                                LinearSlider(value: bFractal.FP.lightParameters.diffuse, range: 0.0...1.0, step: 0.05, format: "%.2f", width: 120)
                            }
                            GridRow {
                                Text("Specular")
                                LinearSlider(value: bFractal.FP.lightParameters.specular, range: 0.0...1.0, step: 0.05, format: "%.2f", width: 120)
                            }
                            GridRow {
                                Text("Shininess")
                                LinearSlider(value: bFractal.FP.lightParameters.shininess, range: 1.0...30.0, format: "%2.0f", width: 120)
                            }
                            GridRow {
                                Text("Gamma")
                                LinearSlider(value: bFractal.FP.lightParameters.gamma, range: 0.1...9.9, step: 0.1, format: "%.1f", width: 120)
                            }
                        }.padding([.top, .bottom, .horizontal], 5)
                    }
                }
            }
        }.padding([.top], 10)

        //
        // Stripes, steps, color cycles
        //
        GroupBox(label: Text("Drawing options").foregroundStyle(.blue).font(.headline)) {
            DisclosureGroup("Stripes & Steps", isExpanded: $isStripesStepsExpanded) {
                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                    GridRow {
                        Text("Stripes")
                        LinearStepper(value: bFractal.FP.colorParameters.stripes, range: 0...32)
                            .onChange(of: fractal.FP.colorParameters.stripes) { oldValue, newValue in
                                if oldValue == 0 && newValue > 0 {
                                    fractal.FP.colorParameters.colorizeMode = ColorizeMode(.stripes)
                                    fractal.FP.colorParameters.colorizeOutside = ColorizeOutside(.blinnPhong)
                                }
                                if oldValue > 0 && newValue == 0 {
                                    fractal.FP.colorParameters.colorizeMode = ColorizeMode(.iterations)
                                    fractal.FP.colorParameters.colorizeOutside = ColorizeOutside(.simple)
                                }
                            }
                        Spacer()
                    }
                    GridRow {
                        Text("Steps")
                        LinearStepper(value: bFractal.FP.colorParameters.steps, range: 0...100)
                            .onChange(of: fractal.FP.colorParameters.steps) { oldValue, newValue in
                                if oldValue == 0 && newValue > 0 {
                                    fractal.FP.colorParameters.colorizeMode = ColorizeMode(.steps)
                                    fractal.FP.colorParameters.colorizeOutside = ColorizeOutside(.blinnPhong)
                                }
                                if oldValue > 0 && newValue == 0 {
                                    fractal.FP.colorParameters.colorizeMode = ColorizeMode(.iterations)
                                    fractal.FP.colorParameters.colorizeOutside = ColorizeOutside(.simple)
                                }
                            }
                        Spacer()
                    }
                }.padding(.horizontal, 5)
            }
            DisclosureGroup("Color changing", isExpanded: $isColorChangingExpanded) {
                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                    GridRow {
                        Text("Compression")
                        LinearStepper(value: bFractal.FP.colorParameters.compression, range: 1...4)
                            .onChange(of: fractal.FP.colorParameters.compression) {
                                Task { await controller.drawResultSet() }
                            }
                    }
                    GridRow {
                        Text("Cycles")
                        LinearStepper(value: bFractal.FP.colorParameters.ncycle, range: 1...200)
                            .onChange(of: fractal.FP.colorParameters.ncycle) {
                                Task { await controller.drawResultSet() }
                            }
                    }
                    GridRow {
                        Text("Scale")
                        NonLinearSlider(value: bFractal.FP.colorParameters.scale, strides: [
                            stride(from: 0.0, through: 0.9, by: 0.1),
                            stride(from: 1.0, through: 9.0, by: 0.5),
                            stride(from: 10.0, through: 50.0, by: 1.0)
                        ], format: "%.1f", width: 120)
                        .onChange(of: fractal.FP.colorParameters.scale) {
                            Task { await controller.drawResultSet() }
                        }
                    }
                    GridRow {
                        Text("Offset")
                        LinearSlider(value: bFractal.FP.colorParameters.offset, range: 0...10, format: "%.0f", width: 120)
                            .onChange(of: fractal.FP.colorParameters.offset) {
                                Task { await controller.drawResultSet() }
                            }
                    }
                }.padding(.horizontal, 5)
            }
        }.padding([.top], 10)
            
        //
        // Iterations
        //
        GroupBox(label: Text("Iteration control").foregroundStyle(.blue).font(.headline)) {
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                GridRow {
                    Toggle(isOn: $autoIterations) { Text("Auto iterations") }
                        .onChange(of: autoIterations) { oldValue, newValue in
                            if newValue {
                                fractal.FP.limits.iterations = fractal.FP.current.maxIterationCount
                            }
                        }
                }
                GridRow {
                    Text("Iterations")
                    LinearStepper(value: bFractal.FP.limits.iterations, range: 0...8192, step: 50)
                        .disabled(autoIterations)
                    Spacer()
                }
            }.padding(.horizontal, 5)
        }.padding([.top], 10)

    }
}
