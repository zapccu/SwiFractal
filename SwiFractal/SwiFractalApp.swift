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
    static let windowSize: CGSize = CGSize(width: 1000, height: 700)
    
    // The default image size
    static let resolution: CGSize = CGSize(width: 800, height: 800)
    
    // The width of the control view
    static let controlViewWidth: CGFloat = 300
    
    // Dictionary with color tables
    static var colorTables: [String: EnumColorTable] = [
        "Grey-1024": .smooth(smoothColorTable: ColorTableSmooth(
            "Grey-1024", colorPoints: [RGBAColor(80.0/255.0, 80.0/255.0, 80.0/255.0), .white], colorCount: 1024, defColor: .black)
        ),
        "Sine-85_0_15-1024": .sine(sineColorTable: ColorTableSine(
            "Sine-85_0_15-1024", thetas: [0.85, 0.0, 0.15], colorCount: 1024, defColor: .black)
        ),
        "Sine-11_02_92-1024": .sine(sineColorTable: ColorTableSine(
            "Sine-11_02_92-1024", thetas: [ 0.11, 0.02, 0.92 ], colorCount: 1024, defColor: .black)
        )
    ]
    
    // The default color table
    static let defaultColorTable: String = "Grey-1024"

    /// Add or replace color table
    /// - Parameter colorTable: Color table object
    static func addColorTable(colorTable: EnumColorTable) {
        FractalAppData.colorTables[colorTable.ct.name] = colorTable
    }
    
}

//
// The application structure
//
@main
struct SwiFractalApp: App {
    
    var appData = FractalAppData()
    
    var body: some Scene {
        WindowGroup {
            ContentView(resolution: FractalAppData.resolution)
                .frame(minWidth: FractalAppData.windowSize.width, minHeight: FractalAppData.windowSize.height)
        }.windowResizability(.contentSize)
    }
    
}
