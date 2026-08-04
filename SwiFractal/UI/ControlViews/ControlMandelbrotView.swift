//
//  CommonView.swift
//  SwiFractal
//
//  Created by Dirk Braner on 23.03.26.
//

import SwiftUI
import SwiftMPx
import ParSetKit

struct ControlMandelbrotView<RT: PreciseFloatingPoint>: View {

    var controller: FractalController
    var fractal: Mandelbrot<RT>

    @Binding var dimensions: FractalDimensions<MPFloat>     // Fractal controller dimensions
    
    // Flags for expanding control groups
    @State private var isLightExpanded = false
    @State private var isShadingExpanded = false
    @State private var isStripesStepsExpanded = false
    @State private var isCyclesSamplingExpanded = false
    
    @State private var autoIterations: Bool = false
    @State private var colorTableName: String = FractalAppData.defaultColorTable
    
    var body: some View {

        //
        // Common information
        //
        GroupBox(label: Text("Info").foregroundStyle(.blue).font(.headline)) {
            Text("Name").gridColumnAlignment(.trailing)
            TextField("", text: Bindable(fractal).FP.name)
                .frame(width: 170)
        }.padding([.top], 10)
        
        //
        // Fractal dimensions and oversampling
        //
        GroupBox(label: Text("Fractal dimensions").foregroundStyle(.blue).font(.headline)) {
            VStack(alignment: .leading) {
                LabeledInputField("Left",   $dimensions.strDimensions.cornerX, width: 170)
                LabeledInputField("Bottom", $dimensions.strDimensions.cornerY, width: 170)
                LabeledInputField("Size X", $dimensions.strDimensions.sizeX, width: 170)
                LabeledInputField("Size Y", $dimensions.strDimensions.sizeY, width: 170)
                LabeledStepper("Sampling:", $dimensions.oversampling, range: 1...3)
            }
        }
        .padding([.top], 10)
        
        //
        // Color table
        //
        GroupBox(label: Text("Color table").foregroundStyle(.blue).font(.headline)) {
            Picker(selection: $colorTableName, label: Text("")) {
                ForEach(FractalAppData.colorTables.keys.sorted(), id: \.self) { key in
                    ColorPalette(
                        colorTable: FractalAppData.colorTables[key]!,
                        size: CGSize(width: 150, height: 20),
                        label: key
                    )
                    .tag(key)
                }
            }.onChange(of: colorTableName) { _, newValue in
                debugPrint("Changing color table to \(newValue)")
                fractal.FP.coloring.colorTable = FractalAppData.colorTables[newValue]!
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
                            LabeledStepper("Angle:", Bindable(fractal).FP.lightParameters.angle, range: 0...360, step: 5, unit: "°")
                            LabeledStepper("Elevation:", Bindable(fractal).FP.lightParameters.elevation, range: 0...90,  step: 5, unit: "°")
                        }
                    }
                }
                GroupBox {
                    DisclosureGroup("Light", isExpanded: $isLightExpanded) {
                        VStack(alignment: .leading, spacing: 8) {
                            LabeledSlider("Opacity:", Bindable(fractal).FP.lightParameters.opacity, range: 0.0...1.0, step: 0.1, width: 100, format: "%.1f")
                            LabeledSlider("Ambient:", Bindable(fractal).FP.lightParameters.ambient, range: 0.0...1.0, step: 0.05, width: 100, format: "%.2f")
                            LabeledSlider("Diffuse:", Bindable(fractal).FP.lightParameters.diffuse, range: 0.0...1.0, step: 0.05, width: 100, format: "%.2f")
                            LabeledSlider("Specular:", Bindable(fractal).FP.lightParameters.specular, range: 0.0...1.0, step: 0.05, width: 100, format: "%.2f")
                            LabeledSlider("Shininess:", Bindable(fractal).FP.lightParameters.shininess, range: 1.0...30.0, step: 1.0, width: 100, format: "%2.0f")
                            LabeledSlider("Gamma:", Bindable(fractal).FP.lightParameters.gamma, range: 0.1...9.9, step: 0.1, width: 100, format: "%.1f")
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
        GroupBox(label: Text("Iteration control").foregroundStyle(.blue).font(.headline)) {
            VStack(alignment: .leading, spacing: 8) {
                Toggle(isOn: $autoIterations) { Text("Auto iterations") }
                    .onChange(of: autoIterations) { oldValue, newValue in
                        if newValue {
                            fractal.FP.limits.iterations = fractal.FP.current.maxIterationCount
                        }
                    }
                LabeledStepper("Iterations:", Bindable(fractal).FP.limits.iterations, range: 0...8192, step: 50)
                    .disabled(autoIterations)
            }
        }.padding([.top], 10)
        Spacer()

    }
}
