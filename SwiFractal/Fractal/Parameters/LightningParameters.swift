//
//  LightningParameters.swift
//  SwiFractal
//
//  Created by Dirk Braner on 24.03.26.
//

import Foundation
import SwiftMPx


///
/// Lightning Parameters
///
struct LightningParameters: FractalParameters {
    
    /// Angle of light source in degrees (0...360)/
    var angle: Int = 45
    
    /// Elevation of light source in degrees (0...90)
    var elevation: Int = 45
    
    /// Opacity of the lightning effect (0...1)/
    var opacity: Double = 0.75
    
    /// Ambient light factor (0...1)
    var ambient: Double = 0.2
    
    /// Diffuse reflection factor (0...1)/
    var diffuse: Double = 0.5
    
    /// Specular reflection factor (0...1)/
    var specular: Double = 0.5
    
    /// Shininess factor for specular reflection
    var shininess: Double = 20.0
    
    /// Gamma correction factor for overlay blending and gamma correction
    var gamma: Float = 1.0

    /// Exposure adjustment for the lightning effect (-3...3)
    var ev: Int = 0

    /// Blending mode for combining lightning with fractal image
    var blendingMode: BlendingMode = BlendingMode(.none)
    
}
