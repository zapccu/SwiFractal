//
//  AppSettings.swift
//  SwiFractal
//
//  Created by Dirk Braner on 04.08.26.
//

import Foundation
import SwiftUI


///
/// Keys for setting parameters
///
enum SettingsKeys {
    static let cpuCount = "settings.cpuCount"
    static let oversubscription = "settings.oversubscription"
    static let resolutionWidth = "settings.resolution.width"
    static let resolutionHeight = "settings.resolution.height"
    static let useSeriesApproximation = "settings.useSeriesApproximation"
    static let perturbationPasses = "settings.perturbationPasses"
    static let fixGlitches = "settings.fixGlitches"
}

///
/// Snapshot of settings. Passed to nonisolated functions via dynamic parameters
///
struct SettingsSnapshot: Sendable {
    
    /// Number of CPUs / cores
    let cpuCount: Int
    
    /// Oversubscription factor. 1 = no oversubscription
    let oversubscription: Int
    
    /// Default resolution of fractal images
    let resolution: CGSize
    
    /// Use series approximation in perturbation algorithm
    let useSeriesApproximation: Bool
    
    /// Number of perturbation passes for fixing of glitches
    let perturbationPasses: Int
    
    /// Fix glitches in perturbation results
    let fixGlitches: Bool
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
    
    /// The default resolution
    private static let defaultResolution = CGSize(width: 800, height: 800)

    /// Number of CPU cores used for calculation
    var cpuCount: Int {
        didSet { defaults.set(cpuCount, forKey: SettingsKeys.cpuCount) }
    }
    
    /// CPU oversubscription factor
    var oversubscription: Int {
        didSet { defaults.set(oversubscription, forKey: SettingsKeys.oversubscription) }
    }

    /// Default image resolution
    var resolution: CGSize {
        didSet {
            defaults.set(Int(resolution.width.rounded()), forKey: SettingsKeys.resolutionWidth)
            defaults.set(Int(resolution.height.rounded()), forKey: SettingsKeys.resolutionHeight)
        }
    }
    
    /// Use series approximation
    var useSeriesApproximation: Bool {
        didSet { defaults.set(useSeriesApproximation, forKey: SettingsKeys.useSeriesApproximation) }
    }
    
    /// Number of perturbation passes
    var perturbationPasses: Int {
        didSet { defaults.set(perturbationPasses, forKey: SettingsKeys.perturbationPasses) }
    }
    
    /// Fix remaining glitches after perturbation passes completed
    var fixGlitches: Bool {
        didSet { defaults.set(fixGlitches, forKey: SettingsKeys.fixGlitches) }
    }

    /// Initialize settings with current or default values
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.cpuCount = defaults.object(forKey: SettingsKeys.cpuCount) as? Int ?? ProcessInfo.processInfo.activeProcessorCount
        self.oversubscription = defaults.object(forKey: SettingsKeys.oversubscription) as? Int ?? 2
        let width = defaults.object(forKey: SettingsKeys.resolutionWidth) as? Int ?? Int(Self.defaultResolution.width)
        let height = defaults.object(forKey: SettingsKeys.resolutionHeight) as? Int ?? Int(Self.defaultResolution.height)
        self.resolution = CGSize(width: Double(width), height: Double(height))
        self.useSeriesApproximation = defaults.object(forKey: SettingsKeys.useSeriesApproximation) as? Bool ?? false
        self.perturbationPasses = defaults.object(forKey: SettingsKeys.perturbationPasses) as? Int ?? 5
        self.fixGlitches = defaults.object(forKey: SettingsKeys.fixGlitches) as? Bool ?? false
    }
    
    /// Return snapshot of current settings
    func snapshot() -> SettingsSnapshot {
        SettingsSnapshot(
            cpuCount: cpuCount,
            oversubscription: oversubscription,
            resolution: resolution,
            useSeriesApproximation: useSeriesApproximation,
            perturbationPasses: perturbationPasses,
            fixGlitches: fixGlitches
        )
    }
    
}


