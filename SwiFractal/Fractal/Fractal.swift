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
        "corner": Cplx(-2.25, -1.5),
        "size": Cplx(3.0, 3.0),
        "oversampling": Int(1),
        "lightning": [
            "angle": Int(45),
            "elevation": Int(45),
            "opacity": 0.75,
            "ambient": 0.2,
            "diffuse": 0.5,
            "specular": 0.5,
            "shininess": 20.0,
            "gamma": 1.0
        ]
    ])
    
    /// Type of fractal (name of fractal class
    var fractalType: String { String(describing: Self.self) }
    
    // Flag for redrawing / recalculation
    // var redraw: Bool = false
    
    // Calculation parameters
    var CP: FractalParameters
    
    // Statistic value
    var startTime: TimeInterval = 0
    var endTime: TimeInterval = 0
    var calculationTime: TimeInterval = 0
    
    // Preformance is dropping when more than 4 CPU cores are used
    let cpuCount: Int = min(ProcessInfo.processInfo.processorCount, 4)
    
    /// Initialize fractal object, add parameters of child class as sub-path-element.
    ///
    /// Parameters:
    ///
    /// childClassName: Name of child class, used as sub-path-element
    /// childClassDct: Dictionary with fractal settings of child class
    ///
    init(_ childClassName: String = "", _ childClassDict: DictAny = [:]) {
        // Add settings of child classes to Fractal.settings ParameterSet
        if !childClassName.isEmpty {
            _ = settings.addSetting(childClassName, childClassDict)
        }
        
        // Create initial calculation parameters from settings ParameterSet
        CP = FractalParameters(settings)
    }
    
    /// Update fractal parameters
    func updateSettings(_ path: String, _ dict: DictAny) {
        settings.updateSettings(dict)
    }
    
    /// Start of calculation
    /// Initialize stop timer
    func beginCalculation() {
        startTime = Date().timeIntervalSince1970
    }
    
    /// End of calculation
    /// Measure calculation time
    func endCalculation() {
        endTime = Date().timeIntervalSince1970
        calculationTime = endTime - startTime
    }
    
    /// Return zoom factor
    func zoomFactor() -> Double {
        let initialSize: Cplx = settings.initial[path: "size"]
        let currentSize: Cplx = settings.current[path: "size"]
        return initialSize.max / currentSize.min
    }
    
    /// Check if Double precision is sufficient for current pixel size
    ///
    /// Returns true, if precision is sufficient
    /// 
    func checkPrecision(_ center: Cplx, _ resolution: Int, _ securityFactor: Double = 100.0) -> Bool {
        let currentSize: Cplx = settings.current[path: "size"]
        let pixelSize = currentSize.min / Double(resolution)
        
        // Security factor = 100
        return pixelSize >= (center.ulp * securityFactor)
    }

}


