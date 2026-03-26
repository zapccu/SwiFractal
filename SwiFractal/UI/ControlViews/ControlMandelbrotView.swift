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
struct ControlMandelbrotView: View {
    
    var fractal: Mandelbrot
    
    // Variables for controlling the behaviour of elements
    @State private var isStripesStepsExpanded = false
    @State private var isCyclesSamplingExpanded = false
    
    @State var autoIterations: Bool = false
    // @State var color: Color = Color.white
    // @State var colorTable: String
    
    var graphics: Graphics              // Graphics

    var body: some View {
        
        VStack(alignment: .leading) {
            
            //
            // Stripes, steps, color cycles
            //
            GroupBox(label: Text("Drawing options").foregroundStyle(.blue).font(.headline)) {
                DisclosureGroup("Stripes & Steps", isExpanded: $isStripesStepsExpanded) {
                    VStack(alignment: .leading) {
                        LabeledStepper("Stripes", Bindable(fractal).FP.colorMapping.stripes, range: 0...32)
                        LabeledStepper("Steps",   Bindable(fractal).FP.colorMapping.steps,   range: 0...100)
                    }
                }
                DisclosureGroup("Cycles", isExpanded: $isCyclesSamplingExpanded) {
                    VStack(alignment: .leading) {
                        LabeledStepper("Cycles:", Bindable(fractal).FP.colorMapping.ncycle, range: 1...200)
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
                        Picker(selection: Bindable(fractal).FP.colorMapping.colorTable, label: Text("")) {
                            ForEach(ColorMapping.colorTables.keys.sorted(), id: \.self) { key in
                                ColorPalette(colorTable: ColorMapping.colorTables[key]!,
                                             size: CGSize(width: 150, height: 20), label: key)
                                .tag(key)
                            }
                        }
                    }
                    OptionsPicker(options: Bindable(fractal).FP.colorMapping.colorizeMode, "Mode")
                        .padding([.top], 10)
                    OptionsPicker(options: Bindable(fractal).FP.colorMapping.colorizeInside, "Inside")
                        .padding([.top], 10)
                    OptionsPicker(options: Bindable(fractal).FP.colorMapping.colorizeOutside, "Outside")
                        .padding([.top], 10)
                    if fractal.FP.colorMapping.colorizeMode == ColorizeMode(.iterations) {
                        OptionsPicker(options: Bindable(fractal).FP.colorMapping.paletteMode, "Mapping")
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
                                fractal.FP.iterations = fractal.maxIterationCount
                            }
                        }
                    LabeledStepper("Iterations:", Bindable(fractal).FP.iterations, range: 0...4096, step: 50)
                        .disabled(autoIterations)
                }
            }.padding([.top], 10)
            Spacer()
        }
    }
    
}

//
// Simplify access to bindings
//

/*
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
*/
