//
//  ControlView.swift
//  SwiFractal
//
//  Created by Dirk Braner on 22.03.26.
//

import SwiftUI
import SwiftMPx


struct ControlView: View {

    @Bindable var controller: FractalController

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
                    Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                        GridRow {
                            LinearStepper(value: Bindable(controller).resolution.width, unit: " px", range: 100...4096, step: 50, format: "%.0f")
                                .onChange(of: controller.resolution.width) { _, newValue in
                                    if linkResolution { controller.resolution.height = newValue }
                                }
                            LinearStepper(value: Bindable(controller).resolution.height, unit: " px", range: 100...4096, step: 50, format: "%.0f")
                                .onChange(of: controller.resolution.height) { _, newValue in
                                    if linkResolution { controller.resolution.width = newValue }
                                }
                            Spacer()
                        }
                        GridRow {
                            Toggle(isOn: $linkResolution) { Text("Aspect ratio") }
                        }
                        GridRow {
                            Toggle("Spherical", isOn: $controller.isSphericalDisplay)
                        }
                        GridRow {
                            Text("Method")
                            CasePicker(selection: $method, width: 120)
                        }
                    }.padding(.horizontal, 5)
                }.padding([.top, .leading], 10)

                switch controller.kind {
                case .mandelbrotDP(let f):
                    ControlParameterView(controller: controller, fractal: f)
                case .mandelbrotAP(let f):
                    ControlParameterView(controller: controller, fractal: f)
                case .juliaDP(let f):
                    ControlParameterView(controller: controller, fractal: f)
                case .juliaAP(let f):
                    ControlParameterView(controller: controller, fractal: f)
                }

            }
        }
    }
}

