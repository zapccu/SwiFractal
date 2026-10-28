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
                    Picker(selection: bFractal.coloringName, label: Text("")) {
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
                        if FractalAppData.colorings.index(forKey: fractal.coloringName) == nil {
                            FractalAppData.addColoring(coloring: fractal.coloring, name: fractal.coloringName)
                        }
                    }.onChange(of: fractal.coloringName) { _, newValue in
                        if let coloring = FractalAppData.colorings[newValue] {
                            fractal.coloring = coloring
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
                    OptionsPicker(options: bFractal.colorizeMode, width: 140)
                        .onChange(of: fractal.colorizeMode) { _, newValue in
                            if newValue == .stripes {
                                if fractal.stripes == 0 { fractal.stripes = 1 }
                                if controller.calcInfo.extendedInfo != .stripes {
                                    ToastCenter.shared.show("Image must be recalculated", systemImage: "checkmark.circle.fill")
                                    return
                                }
                            }
                            else if newValue == .steps {
                                if fractal.steps == 0 { fractal.steps = 1 }
                            }
                            Task { await controller.drawResultSet() }
                        }
                }
                GridRow {
                    Text("Inside")
                    OptionsPicker(options: bFractal.colorizeInside, width: 140)
                        .onChange(of: fractal.colorizeInside) {
                            if fractal.colorizeInside == .orbits {
                                if controller.calcInfo.extendedInfo != .orbits {
                                    ToastCenter.shared.show("Image must be recalculated", systemImage: "checkmark.circle.fill")
                                    return
                                }
                                ToastCenter.shared.show("Image must be recalculated", systemImage: "checkmark.circle.fill")
                            }
                            Task { await controller.drawResultSet() }
                        }
                }
                GridRow {
                    Text("Orbitlength")
                    LinearStepper(value: bFractal.orbitLength, range: 10...100, step: 10)
                        .disabled(fractal.colorizeInside == .defaultColor || fractal.colorizeInside == .distance)
                }
                GridRow {
                    Text("Outside")
                    OptionsPicker(options: bFractal.colorizeOutside, width: 140)
                        .onChange(of: fractal.colorizeOutside) {
                            debugPrint("Changed outside")
                            if fractal.colorizeOutside != .simple && fractal.blendingMode == .none {
                                fractal.blendingMode(.multiply)
                            }
                            Task { await controller.drawResultSet() }
                        }
                }
                if fractal.colorizeMode == .iterations {
                    GridRow {
                        Text("Mapping")
                        OptionsPicker(options: bFractal.paletteMode, width: 140)
                            .onChange(of: fractal.paletteMode) {
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
                                LinearStepper(value: bFractal.angle, unit: "°", range: 0...360, step: 5)
                                    .onChange(of: fractal.angle) {
                                        Task { await controller.drawResultSet() }
                                    }
                                Spacer()
                            }
                            GridRow {
                                Text("Elevation")
                                LinearStepper(value: bFractal.elevation, unit: "°", range: 0...90, step: 5)
                                    .onChange(of: fractal.elevation) {
                                        Task { await controller.drawResultSet() }
                                    }
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
                                LinearSlider(value: bFractal.opacity, range: 0.0...1.0, step: 0.1, format: "%.1f", width: 120)
                                    .onChange(of: fractal.opacity) {
                                        Task { await controller.drawResultSet() }
                                    }
                            }
                            GridRow {
                                Text("Ambient")
                                LinearSlider(value: bFractal.ambient, range: 0.0...1.0, step: 0.05, format: "%.2f", width: 120, debounce: 0, action: controller.drawResultSet)
                            }
                            GridRow {
                                Text("Diffuse")
                                LinearSlider(value: bFractal.diffuse, range: 0.0...1.0, step: 0.05, format: "%.2f", width: 120)
                            }
                            GridRow {
                                Text("Specular")
                                LinearSlider(value: bFractal.specular, range: 0.0...1.0, step: 0.05, format: "%.2f", width: 120)
                                    .onChange(of: fractal.specular) {
                                        Task { await controller.drawResultSet() }
                                    }
                            }
                            GridRow {
                                Text("Shininess")
                                LinearSlider(value: bFractal.shininess, range: 1.0...30.0, format: "%2.0f", width: 120)
                                    .onChange(of: fractal.shininess) {
                                        Task { await controller.drawResultSet() }
                                    }
                            }
                            GridRow {
                                Text("Gamma")
                                LinearSlider(value: bFractal.gamma, range: 0.1...9.9, step: 0.1, format: "%.1f", width: 120)
                                    .onChange(of: fractal.gamma) {
                                        Task { await controller.drawResultSet() }
                                    }
                            }
                            GridRow {
                                Text("Exposure")
                                LinearStepper(value: bFractal.ev, unit: "Stops", range: -3...3, step: 1)
                                    .onChange(of: fractal.ev) {
                                        Task { await controller.drawResultSet() }
                                    }
                            }
                            GridRow {
                                Text("Blending")
                                OptionsPicker(options: bFractal.blendingMode, width: 140)
                                    .onChange(of: fractal.blendingMode) {
                                        debugPrint("Changed blending")
                                        Task { await controller.drawResultSet() }
                                    }
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
                        LinearStepper(value: bFractal.stripes, range: 0...32)
                            .onChange(of: fractal.stripes) { oldValue, newValue in
                                if oldValue == 0 && newValue > 0 {
                                    fractal.colorizeMode(.stripes)
                                    fractal.colorizeOutside(.blinnPhong)
                                }
                                if oldValue > 0 && newValue == 0 {
                                    fractal.colorizeMode(.iterations)
                                    fractal.colorizeOutside(.simple)
                                }
                            }
                        Spacer()
                    }
                    GridRow {
                        Text("Steps")
                        LinearStepper(value: bFractal.steps, range: 0...100)
                            .onChange(of: fractal.steps) { oldValue, newValue in
                                if oldValue == 0 && newValue > 0 {
                                    fractal.colorizeMode(.steps)
                                    fractal.colorizeOutside(.blinnPhong)
                                }
                                if oldValue > 0 && newValue == 0 {
                                    fractal.colorizeMode(.iterations)
                                    fractal.colorizeOutside(.simple)
                                }
                                Task { await controller.drawResultSet() }
                            }
                        Spacer()
                    }
                }.padding(.horizontal, 5)
            }
            DisclosureGroup("Color changing", isExpanded: $isColorChangingExpanded) {
                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                    GridRow {
                        Text("Compression")
                        LinearStepper(value: bFractal.compression, range: 1...4)
                            .onChange(of: fractal.compression) {
                                Task { await controller.drawResultSet() }
                            }
                    }
                    GridRow {
                        Text("Cycles")
                        LinearStepper(value: bFractal.ncycle, range: 1...200)
                            .onChange(of: fractal.ncycle) {
                                Task { await controller.drawResultSet() }
                            }
                    }
                    GridRow {
                        Text("Scale")
                        NonLinearSlider(value: bFractal.scale, strides: [
                            stride(from: 0.0, through: 0.9, by: 0.1),
                            stride(from: 1.0, through: 9.0, by: 0.5),
                            stride(from: 10.0, through: 50.0, by: 1.0)
                        ], format: "%.1f", width: 120)
                        .onChange(of: fractal.scale) {
                            Task { await controller.drawResultSet() }
                        }
                    }
                    GridRow {
                        Text("Offset")
                        LinearSlider(value: bFractal.offset, range: 0...10, format: "%.0f", width: 120)
                            .onChange(of: fractal.offset) {
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
