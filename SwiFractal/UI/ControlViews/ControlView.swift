//
//  ControlView.swift
//  SwiFractal
//
//  Created by Dirk Braner on 22.03.26.
//

import SwiftUI
import SwiftMPx


struct ControlView: View {

    let controller: FractalController

    @State var linkResolution: Bool = true
    @State var method: CalculationMethod = .sequential

    /// Binding for FractalController
    var bController: Bindable<FractalController> {
        Bindable(controller)
    }
    
    // Only UI changes of width will change the controller resolution
    private var width: Binding<CGFloat> {
        Binding(
            get: { controller.resolution.width },
            set: { newValue in
                let delta = newValue - controller.resolution.width
                controller.resolution.width = newValue
                if linkResolution {
                    controller.resolution.height += delta
                }
            }
        )
    }
   
    // Only UI changes of height will change the controller resolution
    private var height: Binding<CGFloat> {
        Binding(
            get: { controller.resolution.height },
            set: { newValue in
                let delta = newValue - controller.resolution.height
                controller.resolution.height = newValue
                if linkResolution {
                    controller.resolution.self.width += delta
                }
            }
        )
    }
    
    var body: some View {
        ScrollView([.vertical]) {
            VStack(alignment: .leading) {
                //
                // Buttons
                //
                ControlButtonView(controller: controller, method: method)
                
                //
                // Resolution
                //
                GroupBox(label: Text("Resolution").foregroundStyle(.blue).font(.headline)) {
                    Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                        GridRow {
                            LinearStepper(value: width, unit: " px", range: 100...4096, step: 50, format: "%.0f")
                            LinearStepper(value: height, unit: " px", range: 100...4096, step: 50, format: "%.0f")
                            Spacer()
                        }
                        GridRow {
                            Toggle(isOn: $linkResolution) { Text("Link width and height") }
                                .gridCellColumns(2)
                        }
                        GridRow {
                            Toggle("Spherical", isOn: bController.isSphericalDisplay)
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
