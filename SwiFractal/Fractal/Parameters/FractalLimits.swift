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
    
    /// Minimum iteration count. Default = 200
    var minIterationCount: Int = 200
    
    /// Maximum number of iterations. Default = 200
    var iterations: Int = 200
    
    /// Bailout radius. Default = 1e10
    var bailout: Double = 1e10
    
    /// Orbit detection: 1st delta. Default = 1e-15
    var orbitDelta1: Double = 1e-15
    
    /// Orbit detection: Delta factor for 2nd pass. Default = 1e4
    var orbitDeltaF: Double = 1e4
    
    /// Orbit detection: delta for fast detection = 1e-10
    var orbitDelta3: Double = 1e-10
    
    /// Limit for fast orbit detection = 20
    var orbitLength: Int = 20
    
    /// Tolerance value for interior distance estimation
    var interiorTolerance: Double = 1e-13
    
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
