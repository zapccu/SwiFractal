//
//  SettingsView 2.swift
//  SwiFractal
//
//  Created by Dirk Braner on 04.08.26.
//

import SwiftUI


///
/// Application settings view
///
struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    
    let maxCoreCount: Int = ProcessInfo.processInfo.activeProcessorCount
    
    var body: some View {
        @Bindable var settings = settings   // create local $-Bindings

        GroupBox(label: Text("Computing").foregroundStyle(.blue).font(.headline)) {
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                GridRow {
                    Text("CPU Count")
                    Stepper("\(settings.cpuCount) cores", value: $settings.cpuCount, in: 1...maxCoreCount)
                }
                GridRow {
                    Text("CPU Oversubscription")
                    Stepper("\(settings.oversubscription)", value: $settings.oversubscription, in: 1...4)
                }
                GridRow {
                    Toggle(isOn: $settings.usePerturbation) { Text("Use perturbation") }
                }
                GridRow {
                    Toggle(isOn: $settings.useSeriesApproximation) { Text("Use series approximation") }
                }
                GridRow {
                    Text("Perturbation passes")
                    Stepper("\(settings.perturbationPasses)", value: $settings.perturbationPasses, in: 1...10)
                }
            }.padding(.horizontal, 5)
        }.padding([.top], 10)
        
        GroupBox(label: Text("Drawing").foregroundStyle(.blue).font(.headline)) {
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                GridRow {
                    Text("Image resolution")
                    Stepper("\(Int(settings.resolution.width)) px", value: $settings.resolution.width, in: 100...4096)
                    Stepper("\(Int(settings.resolution.height)) px", value: $settings.resolution.height, in: 100...4096)
                }
                GridRow {
                    Toggle(isOn: $settings.drawParallel) { Text("Draw parallel") }
                }
            }.padding(.horizontal, 5)
        }.padding([.top], 10)
    }
}
