//
//  CommonView.swift
//  SwiFractal
//
//  Created by Dirk Braner on 23.03.26.
//

import SwiftUI


struct ControlCommonView<T: FractalData>: View {
    
    var fractal: Fractal<T>
    
    @Binding var resolution: CGSize

    @State var linkResolution: Bool = true
    @State var drawMethod: DrawMethod = .sequential
    
    @State private var isLightExpanded = false
    @State private var isShadingExpanded = false

    var body: some View {
        
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
                }.frame(alignment: .leading)
                Toggle(isOn: $linkResolution) { Text("Aspect ratio") }
                LabeledPicker(label: "Method", selection: $drawMethod)
            }
        }.padding([.top], 10)
        
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

    }
}
