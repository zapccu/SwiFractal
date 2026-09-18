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
    
    let maxCoreCount: Double = Double(ProcessInfo.processInfo.activeProcessorCount)
    
    var body: some View {
        @Bindable var settings = settings   // create local $-Bindings

        Form {
            Section(header: Text("Computing")) {
                HStack {
                    Text("CPU Count")
                    Spacer()
                    Text("\(settings.cpuCount) cores")
                        .foregroundColor(.secondary)
                }
                Stepper("CPU Count", value: $settings.cpuCount)
            }
            Section(header: Text("Drawing")) {
                HStack {
                    Toggle(isOn: $settings.drawParallel) { Text("Draw parallel") }
                }
            }
        }
        .padding(20)
        .frame(width: 350, height: 250)
    }
}
