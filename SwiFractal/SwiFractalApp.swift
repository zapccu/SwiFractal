//
//  SwiFractalApp.swift
//  SwiFractal
//
//  Created by Dirk Braner on 15.11.24.
//

import SwiftUI


///
/// Application data
///
@MainActor
class FractalAppData {
    
    // The default window size
    static let windowSize: CGSize = CGSize(width: 1200, height: 900)
    
    // The default image size
    static let resolution: CGSize = CGSize(width: 800, height: 800)
    
    // The width of the control view
    static let controlViewWidth: CGFloat = 300
    
    /// Dictionary with colorings
    static var colorings: [String: EnumColoring] = [
        "Grey-1024": .smooth(smoothColorTable: ColorTableSmooth(
            "Grey-1024", colorPoints: [RGBAColor(80.0/255.0, 80.0/255.0, 80.0/255.0), .white], colorCount: 1024, defColor: .black)
        ),
        "Sine-85_0_15-1024": .sine(sineColorTable: ColorTableSine(
            "Sine-85_0_15-1024", thetas: [0.85, 0.0, 0.15], colorCount: 1024, defColor: .black)
        ),
        "Sine-11_02_92-1024": .sine(sineColorTable: ColorTableSine(
            "Sine-11_02_92-1024", thetas: [ 0.11, 0.02, 0.92 ], colorCount: 1024, defColor: .black)
        ),
        "Cosine_Rainbow": .cosine(cosineColoring: CosineColoring("Cosine_Rainbow", offset: SIMD3<Float>(0.5, 0.5, 0.5), amplitude: SIMD3<Float>(0.5, 0.5, 0.5), frequency: SIMD3<Float>(1.0, 1.0, 1.0), phase: SIMD3<Float>(0.0, 0.33, 0.67), defColor: .black)
        ),
        "Cosine_Fire": .cosine(cosineColoring: CosineColoring("Cosine_Fire", offset: SIMD3<Float>(0.5, 0.5, 0.5), amplitude: SIMD3<Float>(0.5, 0.5, 0.5), frequency: SIMD3<Float>(2.0, 1.0, 0.0), phase: SIMD3<Float>(0.5, 0.2, 0.25), defColor: .black)
        ),
        "Cosine_Ocean": .cosine(cosineColoring: CosineColoring("Cosine_Ocean", offset: SIMD3<Float>(0.5, 0.5, 0.5), amplitude: SIMD3<Float>(0.5, 0.5, 0.5), frequency: SIMD3<Float>(1.0, 1.0, 0.5), phase: SIMD3<Float>(0.3, 0.2, 0.8), defColor: .black)
        ),
        "Cosine_Neon": .cosine(cosineColoring: CosineColoring("Cosine_Neon", offset: SIMD3<Float>(0.8, 0.5, 0.4), amplitude: SIMD3<Float>(0.2, 0.4, 0.2), frequency: SIMD3<Float>(2.0, 1.0, 1.0), phase: SIMD3<Float>(0.0, 0.25, 0.25), defColor: .black)
        ),
        "LCH_Classic": .lch(
            lchColorTable: ColorTableLCH(
                "LCH_Classic", parameters: LCHParameters(
                    lumMin: 0.0, lumRange: 75.0, lumExponent: 1.0,
                    satBase: 28.0, satRange: 75.0, satExponent: 1.0,
                    hueStart: 0.0, hueRange: 360.0, hueExponent: 1.5
                ),
                colorCount: 2048, defColor: .black
            )
        ),
        "LCH Fire & Magma": .lch(
            lchColorTable: ColorTableLCH(
                "LCH Fire & Magma", parameters: LCHParameters(
                    lumMin: 10.0, lumRange: 85.0, lumExponent: 0.7,
                    satBase: 0.0, satRange: 90.0, satExponent: 1.0,
                    hueStart: 0.0, hueRange: 60.0, hueExponent: 1.2
                ),
                colorCount: 2048, defColor: .black
            )
        ),
        "LCH Cyberpunk Neon": .lch(
            lchColorTable: ColorTableLCH(
                "LCH Cyberpunk Neon", parameters: LCHParameters(
                    lumMin: 35.0, lumRange: 55.0, lumExponent: 1.0,
                    satBase: 70.0, satRange: 40.0, satExponent: 1.0,
                    hueStart: 320.0, hueRange: -130.0, hueExponent: 0.8
                ),
                colorCount: 2048, defColor: .black
            )
        ),
        "LCH Soft Pastel": .lch(
            lchColorTable: ColorTableLCH(
                "LCH Soft Pastel", parameters: LCHParameters(
                    lumMin: 75.0, lumRange: 15.0, lumExponent: 1.0,
                    satBase: 20.0, satRange: 20.0, satExponent: 1.0,
                    hueStart: 180.0, hueRange: 360.0, hueExponent: 1.0
                ),
                colorCount: 2048, defColor: .black
            )
        )
    ]
    
    // The default coloring
    static let defaultColoring: String = "Grey-1024"

    /// Add or replace coloring
    /// - Parameter coloring: Coloring object
    static func addColoring(coloring: EnumColoring, name: String = "") {
        FractalAppData.colorings[name.isEmpty ? coloring.coloringType.name : name] = coloring
    }
    
}

//
// The application structure
//
@main
struct SwiFractalApp: App {

    let settings = AppSettings.shared
    var appData = FractalAppData()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: FractalAppData.windowSize.width, minHeight: FractalAppData.windowSize.height)
                .environment(settings)
        }
        .windowResizability(.contentSize)

        Settings {
            SettingsView()
                .environment(settings)
        }
    }
}
