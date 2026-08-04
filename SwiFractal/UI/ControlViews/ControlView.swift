//
//  ControlView.swift
//  SwiFractal
//
//  Created by Dirk Braner on 22.03.26.
//

import SwiftUI
import SwiftMPx


struct ControlView: View {

    var controller: FractalController

    // Bindings from parent view
    //@Binding var selection: Selection
    @Binding var info: Info
    
    @State var linkResolution: Bool = true
    @State var method: CalculationMethod = .sequential

    var body: some View {
        ScrollView([.vertical]) {
            VStack(alignment: .leading) {
                //
                // Buttons
                //
                ControlButtonView(controller: controller, method: method, info: $info)
                
                //
                // Resolution
                //
                GroupBox(label: Text("Resolution").foregroundStyle(.blue).font(.headline)) {
                    VStack(alignment: .leading) {
                        HStack(spacing: 20) {
                            Stepper("\(controller.resolution.width.formatted()) px", value: Bindable(controller).resolution.width, in: 100...4096, step: 50) { actionInProgress in
                                if linkResolution { controller.resolution.height = controller.resolution.width }
                            }
                            Stepper("\(controller.resolution.height.formatted()) px", value: Bindable(controller).resolution.height, in: 100...4096, step: 50) { actionInProgress in
                                if linkResolution { controller.resolution.width = controller.resolution.height }
                            }
                            Spacer()
                        }
                        Toggle(isOn: $linkResolution) { Text("Aspect ratio") }
                        LabeledPicker(label: "Method", selection: $method)
                    }
                }.padding([.top, .leading], 10)
                
                switch controller.kind {
                case .mandelbrotDP(let f):
                    ControlMandelbrotView(controller: controller, fractal: f, dimensions: Bindable(controller).dimensions)
                case .mandelbrotAP(let f):
                    ControlMandelbrotView(controller: controller, fractal: f, dimensions: Bindable(controller).dimensions)
                case .juliaDP(let f):
                    ControlJuliaView(controller: controller, fractal: f, dimensions: Bindable(controller).dimensions)
                case .juliaAP(let f):
                    ControlJuliaView(controller: controller, fractal: f, dimensions: Bindable(controller).dimensions)                }
            }
        }
    }
}
