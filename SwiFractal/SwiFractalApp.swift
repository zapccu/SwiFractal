//
//  SwiFractalApp.swift
//  SwiFractal
//
//  Created by Dirk Braner on 15.11.24.
//

import SwiftUI

@main
struct SwiFractalApp: App {
    var fractal: Mandelbrot = Mandelbrot()
    
    var body: some Scene {
        WindowGroup {
            ContentView(fractal: fractal).frame(minWidth: 800, minHeight: 800)
        }
    }
}
