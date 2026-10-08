//
//  FractalLimits.swift
//  SwiFractal
//
//  Created by Dirk Braner on 18.09.26.
//

import Foundation


///
/// Fractal calculation limits
///
struct FractalLimits: FractalParameters {
    var minIterationCount: Int = 200                // Minimum iteration count
    var iterations: Int = 200                       // Maximum number of iterations. default = 200
    var bailout: Double = 1e10                      // Bailout radius. default = 1e10
    var orbitDelta1: Double = 1e-15                 // Orbit detection: 1st delta = 1e-15
    var orbitDelta2: Double = 1e-11                 // Orbit detection: 2nd delta = 1e-11
    var orbitDelta3: Double = 1e-10                 // Orbit detection: delta for fast detection = 1e-10
    var orbitLength: Int = 20                       // Limit for fast orbit detection = 20
}

///
/// Dynamic calculation limits
///
@dynamicMemberLookup
struct FractalDynamicLimits: FractalParameters {
    let parameters: FractalLimits
    
    let logBailout: Double                          // log(bailout)
    let div_logBailout_2: Double                    // 0.5 * log(bailout)
    let div_2_logBailout: Double                    // 2.0 / log(bailout)
    let div_05_logBailout: Double                   // 0.5 / log(bailout) = log(bailout) / 2.0

    /// Direct access to fractal limits
    subscript<V>(dynamicMember keyPath: WritableKeyPath<FractalLimits, V>) -> V {
        get { parameters[keyPath: keyPath] }
    }
    
    init(_ parameters: FractalLimits) {
        self.parameters = parameters
        
        self.logBailout = log(parameters.bailout)
        self.div_logBailout_2 = 0.5 * logBailout
        self.div_2_logBailout = 2.0 / logBailout
        self.div_05_logBailout = 0.5 / logBailout
    }
}
