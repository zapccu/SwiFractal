//
//  CommonView.swift
//  SwiFractal
//
//  Created by Dirk Braner on 23.03.26.
//

import SwiftUI
import ParSetKit

struct ControlCommonView: View {
    //var fractal: Fractal<T, P>
    var controller: FractalController
    
    @Binding var resolution: CGSize
    @Binding var fit: AspectRatioMode
    @Binding var method: CalculationMethod

    @State var linkResolution: Bool = true
    
    @State private var isLightExpanded = false
    @State private var isShadingExpanded = false
    
    @State private var presetName: String = "Mandelbrotset"
    @State private var colorTableIndex: Int = 0

    var body: some View {

        //
        // Preset
        //
        GroupBox(label: Text("Info").foregroundStyle(.blue).font(.headline)) {
            HStack {
                Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 10) {
                    GridRow {
                        Text("Name").gridColumnAlignment(.trailing)
                        TextField("", text: Bindable(fractal).FP.common.name)
                            .frame(width: 170)
                    }
                    
                    GridRow {
                        Picker(selection: $fit, label: Text("Fit to:")) {
                            Text("Image").tag(AspectRatioMode.fitToImageSize)
                            Text("Fractal").tag(AspectRatioMode.fitToFractalSize)
                        }
                        .pickerStyle(.radioGroup)
                        .horizontalRadioGroupLayout()
                    }.gridCellColumns(2)
                }.padding(5)
                Spacer()
            }
        }.padding([.top], 10)

        //
        // Resolution
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
                }
                Toggle(isOn: $linkResolution) { Text("Aspect ratio") }
                LabeledPicker(label: "Method", selection: $method)
            }
        }.padding([.top, .leading], 10)
        
        //
        // Fractal dimensions and oversampling
        //
        GroupBox(label: Text("Fractal dimensions").foregroundStyle(.blue).font(.headline)) {
            VStack(alignment: .leading) {
                LabeledInputField("Left",   Bindable(fractal).FP.common.cornerX, width: 170)
                LabeledInputField("Bottom", Bindable(fractal).FP.common.cornerY, width: 170)
                LabeledInputField("Size X", Bindable(fractal).FP.common.sizeX, width: 170)
                LabeledInputField("Size Y", Bindable(fractal).FP.common.sizeY, width: 170)
                LabeledStepper("Sampling:", Bindable(fractal).FP.common.oversampling, range: 1...3)
            }
        }.padding([.top], 10)
        
        //
        // Color table
        //
        GroupBox(label: Text("Color table").foregroundStyle(.blue).font(.headline)) {
            Picker(selection: $colorTableIndex, label: Text("")) {
                ForEach(FractalAppData.colorTables.indices, id: \.self) { index in
                    let table = FractalAppData.colorTables[index]
                    ColorPalette(
                        colorTable: table,
                        size: CGSize(width: 150, height: 20),
                        label: table.ct.name
                    )
                    .tag(index)
                }
            }.onChange(of: colorTableIndex) { _, newValue in
                debugPrint("Changing color table to \(newValue) = \(FractalAppData.colorTables[newValue].ct.name)")
                fractal.FP.common.colorTable = FractalAppData.colorTables[newValue]
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
                            LabeledStepper("Angle:", Bindable(fractal).FP.common.lightning.angle, range: 0...360, step: 5, unit: "°")
                            LabeledStepper("Elevation:", Bindable(fractal).FP.common.lightning.elevation, range: 0...90,  step: 5, unit: "°")
                        }
                    }
                }
                GroupBox {
                    DisclosureGroup("Light", isExpanded: $isLightExpanded) {
                        VStack(alignment: .leading, spacing: 8) {
                            LabeledSlider("Opacity:", Bindable(fractal).FP.common.lightning.opacity, range: 0.0...1.0, step: 0.1, width: 100, format: "%.1f")
                            LabeledSlider("Ambient:", Bindable(fractal).FP.common.lightning.ambient, range: 0.0...1.0, step: 0.05, width: 100, format: "%.2f")
                            LabeledSlider("Diffuse:", Bindable(fractal).FP.common.lightning.diffuse, range: 0.0...1.0, step: 0.05, width: 100, format: "%.2f")
                            LabeledSlider("Specular:", Bindable(fractal).FP.common.lightning.specular, range: 0.0...1.0, step: 0.05, width: 100, format: "%.2f")
                            LabeledSlider("Shininess:", Bindable(fractal).FP.common.lightning.shininess, range: 1.0...30.0, step: 1.0, width: 100, format: "%2.0f")
                            LabeledSlider("Gamma:", Bindable(fractal).FP.common.lightning.gamma, range: 0.1...9.9, step: 0.1, width: 100, format: "%.1f")
                        }
                    }
                }
            }
        }.padding([.top], 10)

        //
        // Stripes, steps, color cycles
        //
        GroupBox(label: Text("Drawing options").foregroundStyle(.blue).font(.headline)) {
            DisclosureGroup("Stripes & Steps", isExpanded: $isStripesStepsExpanded) {
                VStack(alignment: .leading) {
                    LabeledStepper("Stripes", Bindable(fractal).FP.coloring.stripes, range: 0...32)
                        .onValueChanged { oldValue, newValue in
                            if oldValue == 0 && newValue > 0 {
                                fractal.FP.coloring.colorizeMode = ColorizeMode(.stripes)
                                fractal.FP.coloring.colorizeOutside = ColorizeOutside(.blinnPhong)
                            }
                            if oldValue > 0 && newValue == 0 {
                                fractal.FP.coloring.colorizeMode = ColorizeMode(.iterations)
                                fractal.FP.coloring.colorizeOutside = ColorizeOutside(.simple)
                            }
                    }
                    LabeledStepper("Steps", Bindable(fractal).FP.coloring.steps,   range: 0...100)
                        .onValueChanged { oldValue, newValue in
                            if oldValue == 0 && newValue > 0 {
                                fractal.FP.coloring.colorizeMode = ColorizeMode(.steps)
                                fractal.FP.coloring.colorizeOutside = ColorizeOutside(.blinnPhong)
                            }
                            if oldValue > 0 && newValue == 0 {
                                fractal.FP.coloring.colorizeMode = ColorizeMode(.iterations)
                                fractal.FP.coloring.colorizeOutside = ColorizeOutside(.simple)
                            }
                        }
                }
            }
            DisclosureGroup("Cycles", isExpanded: $isCyclesSamplingExpanded) {
                VStack(alignment: .leading) {
                    LabeledStepper("Cycles:", Bindable(fractal).FP.coloring.ncycle, range: 1...200)
                }
            }
        }.padding([.top], 10)
            
        //
        // Coloring
        //
        GroupBox(label: Text("Coloring").foregroundStyle(.blue).font(.headline)) {
            VStack(alignment: .leading) {
                OptionsPicker(options: Bindable(fractal).FP.coloring.colorizeMode, "Mode")
                    .onValueChanged { newValue in
                        if newValue == .stripes && fractal.FP.coloring.stripes == 0 { fractal.FP.coloring.stripes = 1 }
                        if newValue == .steps && fractal.FP.coloring.steps == 0 { fractal.FP.coloring.steps = 1 }
                    }
                    .padding([.top], 10)
                OptionsPicker(options: Bindable(fractal).FP.coloring.colorizeInside, "Inside")
                    .padding([.top], 10)
                OptionsPicker(options: Bindable(fractal).FP.coloring.colorizeOutside, "Outside")
                    .padding([.top], 10)
                if fractal.FP.coloring.colorizeMode == ColorizeMode(.iterations) {
                    OptionsPicker(options: Bindable(fractal).FP.coloring.paletteMode, "Mapping")
                        .padding([.top], 10)
                }
            }
        }.padding([.top], 10)
            
        //
        // Iterations
        //
        GroupBox(label: Text("Mandelbrot Set").foregroundStyle(.blue).font(.headline)) {
            VStack(alignment: .leading, spacing: 8) {
                Toggle(isOn: $autoIterations) { Text("Auto iterations") }
                    .onChange(of: autoIterations) { oldValue, newValue in
                        if newValue {
                            fractal.FP.limits.iterations = fractal.maxIterationCount
                        }
                    }
                LabeledStepper("Iterations:", Bindable(fractal).FP.limits.iterations, range: 0...8192, step: 50)
                    .disabled(autoIterations)
            }
        }.padding([.top], 10)
        Spacer()

    }
}
