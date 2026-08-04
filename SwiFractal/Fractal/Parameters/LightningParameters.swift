//
//  LightningParameters.swift
//  SwiFractal
//
//  Created by Dirk Braner on 24.03.26.
//

import Foundation
import SwiftMPx

//
// Lightning Parameters
//
struct LightningParameters: FractalParameters {
    
    var angle: Int = 45
    var elevation: Int = 45
    var opacity: Double = 0.75
    var ambient: Double = 0.2
    var diffuse: Double = 0.5
    var specular: Double = 0.5
    var shininess: Double = 20.0
    var gamma: Double = 1.0
    
}
