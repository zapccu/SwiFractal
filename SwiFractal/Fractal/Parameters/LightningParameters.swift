//
//  LightningParameters.swift
//  SwiFractal
//
//  Created by Dirk Braner on 24.03.26.
//

import Foundation

//
// Lightning Parameters
//
struct LightningParameters: FractalParameters {
    
    // Default values
    static let defaultValues: [String : Any] = [
        "angle":        45 as Int,
        "elevation":    45 as Int,
        "opacity":      0.75 as Double,
        "ambient":      0.2 as Double,
        "diffuse":      0.5 as Double,
        "specular":     0.5 as Double,
        "shininess":    20.0 as Double,
        "gamma":        1.0 as Double
    ]
    
    var angle: Int = 45
    var elevation: Int = 45
    var opacity: Double = 0.75
    var ambient: Double = 0.2
    var diffuse: Double = 0.5
    var specular: Double = 0.5
    var shininess: Double = 20.0
    var gamma: Double = 1.0
}
