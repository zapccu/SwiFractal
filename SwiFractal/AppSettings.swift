//
//  AppSettings.swift
//  SwiFractal
//
//  Created by Dirk Braner on 04.08.26.
//

import SwiftUI

///
/// Keys for setting parameters
///
enum SettingsKeys {
    static let cpuCount = "settings.cpuCount"
    static let drawParallel = "settings.drawParallel"
    static let resolution = "settings.resolution"
    static let usePerturbation = "settings.usePerturbation"
    static let useSeriesApproximation = "settings.useSeriesApproximation"
}

///
/// Snapshot of settings. Passed to nonisolated functions via dynamic parameters
///
struct SettingsSnapshot: Sendable {
    let cpuCount: Int
    let drawParallel: Bool
    let resolution: CGSize
    let usePerturbation: Bool
    let useSeriesApproximation: Bool
}

///
/// Manager for application settings
///
/// Store in environment:
///
/// ```
/// WindowGroup {
/// ContentView()
///    .environment(AppSettings.shared)
///}
/// ```
///
/// Access in views:
///
/// ```
/// struct ContentView: View {
///    @Environment(AppSettings.self) private var settings
///
///    var body: some View {
///        @Bindable var settings = settings
///        Stepper("CPU Count: \(settings.cpuCount)", value: $settings.cpuCount, in: 1...12)
///    }
/// }
/// ```
///
/// For simple cases:
///
/// ```
/// @AppStorage("settings.cpuCount") var cpuCount = 4
/// ```
@Observable
@MainActor
final class AppSettings {
    static let shared = AppSettings()

    private let defaults: UserDefaults

    /// Number of CPU cores used for calculation
    var cpuCount: Int {
        didSet { defaults.set(cpuCount, forKey: SettingsKeys.cpuCount) }
    }

    /// Draw calculation result parallel or sequential
    var drawParallel: Bool {
        didSet { defaults.set(drawParallel, forKey: SettingsKeys.drawParallel) }
    }

    /// Default image resolution
    var resolution: CGSize {
        didSet { defaults.set(resolution, forKey: SettingsKeys.resolution) }
    }
    
    /// Always use perturbation method
    var usePerturbation: Bool {
        didSet { defaults.set(usePerturbation, forKey: SettingsKeys.usePerturbation) }
    }
    
    /// Use series approximation
    var useSeriesApproximation: Bool {
        didSet { defaults.set(useSeriesApproximation, forKey: SettingsKeys.useSeriesApproximation) }
    }

    /// Initialize settings with current or default values
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.cpuCount = defaults.object(forKey: SettingsKeys.cpuCount) as? Int ?? ProcessInfo.processInfo.activeProcessorCount
        self.drawParallel = defaults.object(forKey: SettingsKeys.drawParallel) as? Bool ?? false
        self.resolution = defaults.object(forKey: SettingsKeys.resolution) as? CGSize ?? CGSize(width: 800, height: 800)
        self.usePerturbation = defaults.object(forKey: SettingsKeys.usePerturbation) as? Bool ?? false
        self.useSeriesApproximation = defaults.object(forKey: SettingsKeys.useSeriesApproximation) as? Bool ?? false
    }
    
    /// Return snapshot of current settings
    func snapshot() -> SettingsSnapshot {
        SettingsSnapshot(cpuCount: cpuCount, drawParallel: drawParallel, resolution: resolution,
                         usePerturbation: usePerturbation, useSeriesApproximation: useSeriesApproximation)
    }
    
}


