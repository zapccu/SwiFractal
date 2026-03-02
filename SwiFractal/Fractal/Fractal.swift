//
//  Fractal.swift
//  SwiFractal
//
//  Created by Dirk Braner on 20.11.24.
//

import Foundation
import SwiftUI
import Numerics

typealias CalcFunc = (Graphics) -> Void

//
// Draw methods
//
enum DrawMethod : String, CaseIterable, Identifiable {
    case sequential
    case parallel
    case metalcompute
    case metalshader
    
    var id: String { "\(Self.self).\(self.rawValue)" }
}

//
// Common fractal class
//

@Observable
class Fractal {
    
    // Store settings as ParameterSet
    static var defaultSettings: ParameterSet = ParameterSet([
        "cornerLeft": "-2.25",
        "cornerBottom": "-1.5",
        "sizeX": "3.0",
        "sizeY": "3.0",
        // "corner": Cplx(-2.25, -1.5),
        // "size": Cplx(3.0, 3.0),
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
    
    var settings: ParameterSet
    
    var calcFunctions: [DrawMethod: CalcFunc?] { [:] }
    
    /// Type of fractal (name of fractal class
    var fractalType: String { String(describing: Self.self) }
    
    // Flag for redrawing / recalculation
    // var redraw: Bool = false
        
    // Calculation parameters
    var CP: FractalParameters
    
    // Statistic value
    let clock: ContinuousClock = ContinuousClock()
    var startTime: ContinuousClock.Instant
    var endTime: ContinuousClock.Instant
    var calculationTime: Duration
    var formattedCalculationTime: String {
        calculationTime.formatted(
            .time(pattern: .hourMinuteSecond(
                padHourToLength: 2, fractionalSecondsLength: 3)
            )
        )
    }
    
    /// Return CPU count
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
            _ = Fractal.defaultSettings.addSetting(childClassName, childClassDict)
        }
        
        settings = Fractal.defaultSettings
        
        startTime = clock.now
        endTime = clock.now
        calculationTime = Duration(attoseconds: 0)
        
        // Create initial calculation parameters from settings ParameterSet
        CP = FractalParameters(Fractal.defaultSettings)
    }
    
    /// Update fractal parameters
    func updateSettings(_ path: String, _ dict: DictAny) {
        settings.updateSettings(dict)
    }
    
    /// Set settings to default settings
    func resetSettings() {
        settings = Fractal.defaultSettings
    }
    
    func zoomArea(_ area: CGRect, _ imageWidth: Int, _ imageHeight: Int) -> (Cplx, Cplx) {
        return (Cplx(0.0), Cplx(0.0))
    }
    
    /// Start of calculation
    /// Initialize stop timer
    func beginCalculation(_ width: Int, _ height: Int) {
        startTime = clock.now
    }
    
    /// End of calculation
    /// Measure calculation time
    func endCalculation() {
        endTime = clock.now
        calculationTime = endTime - startTime
    }
    
    func draw(_ graphics: Graphics, _ method: DrawMethod) {
        if let fnc = calcFunctions[method] {
            graphics.clear(color: .blue)
            beginCalculation(graphics.width, graphics.height)
            
            print("Rendering Mandelbrot with method \(method)")
            fnc!(graphics)
            
            endCalculation()
            print("calculation time: \(calculationTime)")
        }
        else {
            print("Draw method \(method) not available for fractal type \(String(describing: Self.self))")
            return
        }
    }


}


