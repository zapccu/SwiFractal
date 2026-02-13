//
//  SwiFractalApp.swift
//  SwiFractal
//
//  Created by Dirk Braner on 15.11.24.
//

import SwiftUI

struct FractalAppData {
    // The window size
    var windowSize: CGSize = CGSize(width: 1000, height: 700)
    var controlViewWidth: CGFloat = 300
    
    // Current fractal object
    var fractal: Mandelbrot = Mandelbrot()
    
    // Dictionary with color tables
    static var colorTables: [String: ColorTable] = [
        "Grey": ColorTable.grey,
        "Sinus": ColorTable.sinus
    ]
    
    // var colorTable: String = "Greyscale"
}

@main
struct SwiFractalApp: App {
    var appData = FractalAppData()
    
    var body: some Scene {
        WindowGroup {
            ContentView(appData: appData).frame(minWidth: appData.windowSize.width, minHeight: appData.windowSize.height)
        }.windowResizability(.contentSize)
    }
}
