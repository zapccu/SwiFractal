//
//  PresetView.swift
//  SwiFractal
//
//  Created by Dirk Braner on 28.06.26.
//

import SwiftUI
import SwiftMPx

//
// Preset view
//
// Show available presets on top of window
//
struct PresetView: View {
    
    let controller: FractalController
    
    // Preset selection
    @State private var selectedKind: FractalKindID = .mandelbrot
    @State private var selectedPresetName: String = "MandelbrotSet"
    @State private var fit: AspectRatioMode = .fitToFractalSize

    /// Return array with presets of specific kind
    private var availablePresets: [FractalPreset] {
        FractalController.presets.filter {
            $0.header?.fractalType == selectedKind.rawValue
        }
    }
    
    var body: some View {
        HStack(spacing: 5) {
            // Picker for fractal type
            Picker("Type", selection: $selectedKind) {
                ForEach(FractalKindID.allCases, id: \.self) { kind in
                    Text(kind.rawValue).tag(kind)
                }
            }
            .onChange(of: selectedKind) { _, _ in
                if let first = availablePresets.first {
                    selectedPresetName = first.name
                    controller.applyPreset(name: first.name, fit: fit)
                }
            }
            .padding(.trailing, 5)

            // Picker for preset. Depends on selected fractal type
            Picker("Preset", selection: $selectedPresetName) {
                ForEach(availablePresets, id: \.name) { preset in
                    Text(preset.name).tag(preset.name)
                }
            }
            .onChange(of: selectedPresetName) { _, newValue in
                controller.applyPreset(name: newValue, fit: fit)
            }
            .padding(.trailing, 5)

            // Picker for aspect ratio handling
            Picker(selection: $fit, label: Text("Fit to:")) {
                Text("Image").tag(AspectRatioMode.fitToImageSize)
                Text("Fractal").tag(AspectRatioMode.fitToFractalSize)
            }
            .pickerStyle(.radioGroup)
            .horizontalRadioGroupLayout()
            .onChange(of: fit) { _, newValue in
                controller.applyPreset(name: selectedPresetName, fit: newValue)
            }
        }
    }

}
