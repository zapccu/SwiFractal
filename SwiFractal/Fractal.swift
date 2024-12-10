//
//  Fractal.swift
//  SwiFractal
//
//  Created by Dirk Braner on 20.11.24.
//

import Foundation
import Numerics

//
// Common fractal class
//
class Fractal {
    // Store settings as ParameterSet
    var settings: ParameterSet = ParameterSet([
        "oversampling": 1,
        "lightning": [
            "angle": 45.0,
            "elevation": 45.0,
            "opacity": 0.75,
            "ambient": 0.2,
            "diffuse": 0.5,
            "specular": 0.5,
            "shininess": 20.0,
            "gamma": 1.0
        ]
    ])
    
    // Type of fractal
    var fractalType: String { "Fractal" }
    
    // Flag for redrawing / recalculation
    var redraw: Bool = false
    
    // Calculation parameters
    var CP: FractalParameters
    
    // Statistic value
    var startTime: TimeInterval = 0
    var endTime: TimeInterval = 0
    var calculationTime: TimeInterval = 0
    
    // Using more than 4 CPU cores will drop performance
    // With 4 CPU cores the calculation time of a 800x800 pixels Mandelbrot set
    // with maxIterations = 500 is about 55 ms = 18 fps
    let cpuCount: Int = min(ProcessInfo.processInfo.processorCount, 4)
    
    /// Initialize fractal object
    ///
    /// Parameters:
    ///
    /// dict: Dictionary with fractal settings
    ///
    init(_ dict: DictPar = [:]) {
        // Add settings of child classes to settings ParameterSet
        settings.addSettings(dict)
        
        // Create initial calculation parameters from settings ParameterSet
        CP = FractalParameters(settings)
    }
    
    /// Update fractal parameters
    func updateSettings(_ dict: DictPar) {
        settings.updateSettings(dict)
    }
    
    /// Start of calculation
    ///
    /// Initialize stop timer
    func beginCalculation() {
        startTime = Date().timeIntervalSince1970
    }
    
    /// End of calculation
    ///
    /// Measure calculation time
    func endCalculation() {
        endTime = Date().timeIntervalSince1970
        calculationTime = endTime - startTime
        print("calculation time: \(calculationTime)")
    }

}


//
// Class for common fractal calculation parameters
//
class FractalParameters {
    var lightning: Lightning
    var oversampling: Int = 1
    
    /// Initialize calculation parameter object
    ///
    /// Parameters:
    ///
    /// parameterset: Parameterset of child classes
    /// 
    init(_ parameterset: ParameterSet = ParameterSet()) {
        let light: DictPar = parameterset["lightning", [:]]
        lightning    = Lightning(light)
        oversampling = parameterset["oversampling", 1]
    }
}
