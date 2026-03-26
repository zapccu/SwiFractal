//
//  Fractal.swift
//  SwiFractal
//
//  Created by Dirk Braner on 20.11.24.
//

import Foundation
import SwiftUI

// External packages
import Numerics
import ParSetKit


// Type for calculation function
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

protocol FractalProtocol : AnyObject {
    var calcFunctions: [DrawMethod: CalcFunc?] { get }
}

//
// Common fractal class
//
@Observable
class Fractal<T: FractalData> : FractalProtocol {
    
    // Fractal parameters
    var FP: ParSet<T>
    
    // Array of calculation methods.
    // Must be initialized in child class with supported calculation functions
    var calcFunctions: [DrawMethod: CalcFunc?] { [:] }
    
    /// Return type of fractal (name of fractal class)
    var fractalType: String { String(describing: Self.self) }
    
    // Flag for redrawing / recalculation
    // var redraw: Bool = false

    // Clock for time measurement
    @ObservationIgnored
    let clock: ContinuousClock = ContinuousClock()

    // Timings
    @ObservationIgnored
    var startTime: ContinuousClock.Instant
    @ObservationIgnored
    var endTime: ContinuousClock.Instant
    @ObservationIgnored
    var calculationTime: Duration
    
    /// Return calculation time as formatted String
    var formattedCalculationTime: String {
        calculationTime.formatted(
            .time(pattern: .hourMinuteSecond(
                padHourToLength: 2, fractionalSecondsLength: 3)
            )
        )
    }
    
    /// Return CPU count (currently limitted to 4)
    @ObservationIgnored
    let cpuCount: Int = min(ProcessInfo.processInfo.processorCount, 4)
    
    /// Initialize fractal object from data structure
    init() {
        self.FP = ParSet(initial: T.defaultData)
        self.startTime = clock.now
        self.endTime = clock.now
        self.calculationTime = Duration(attoseconds: 0)
    }
    
    /// Initialize fractal object from dictionary.
    /// Return nil if initialization failed
    init?(dictionary: [String: Any]) {
        do {
            self.FP = try ParSet(dictionary: dictionary)
        } catch {
            debugPrint("Failed to initialize fractal data \(error)")
            return nil
        }
        
        self.startTime = clock.now
        self.endTime = clock.now
        self.calculationTime = Duration(attoseconds: 0)
    }
    
    /// Set settings to default settings
    func resetSettings() {
        FP.reset()
    }
    
    func zoomArea(_ area: CGRect, _ imageWidth: Int, _ imageHeight: Int) -> (Cplx, Cplx) {
        return (Cplx(0.0), Cplx(0.0))
    }
    
    /// Start of calculation. Initialize timer
    func beginCalculation(_ width: Int, _ height: Int) {
        startTime = clock.now
    }
    
    /// End of calculation. Measure calculation time
    func endCalculation() {
        endTime = clock.now
        calculationTime = endTime - startTime
    }
    
    /// Render fractal. Return false on error
    nonisolated func draw(_ graphics: Graphics, _ method: DrawMethod) async -> Bool {
        if let fnc = calcFunctions[method] as? CalcFunc {
            graphics.clear(color: .blue)
            
            beginCalculation(graphics.width, graphics.height)
            
            debugPrint("Rendering Mandelbrot with method \(method)")
            fnc(graphics)
            
            endCalculation()
            debugPrint("calculation time: \(calculationTime)")
            
            return true
        }
        else {
            debugPrint("Draw method \(method) not available for fractal type \(fractalType)")
            return false
        }
    }

}


