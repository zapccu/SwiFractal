//
//  Lightning.swift
//  SwiFractal
//
//  Created by Dirk Braner on 09.12.24.
//
//  Implementation of a lightning object.
//

import Foundation
import Numerics


//
// Lightning parameters and methods
//
struct Lightning {
    var angle: Int
    var elevation: Int
    var opacity: Double
    var ambient: Double
    var diffuse: Double
    var specular: Double
    var shininess: Double
    var gamma: Double
    
    // Vectors for Blinn-Phong-Shading
    var vecLight: Vector
    var vecAzimuth: Vector
    
    // Vector and height factor for simple shading
    var vecSimple: Vector
    var height: Double
    
    ///
    /// Initialize lightning object
    ///
    /// Parameters:
    ///
    /// parameters: ParameterSet with lightning settings
    ///
    init(_ parameters: ParameterSet) {
        angle     = parameters["angle",     default: Int(45)]
        elevation = parameters["elevation", default: Int(45)]
        opacity   = parameters["opacity",   default: 0.75]
        ambient   = parameters["ambient",   default: 0.2]
        diffuse   = parameters["diffuse",   default: 0.5]
        specular  = parameters["specular",  default: 0.5]
        shininess = parameters["shininess", default: 20.0]
        gamma     = parameters["gamma",     default: 1.0]
        
        // Convert angles from degree to rad
        let angleRad     = deg2rad(Double(angle))
        let elevationRad = deg2rad(Double(elevation))
        
        // angle = theta, elevation = phi
        // light vector = [ cos(theta) * cos(phi), sin(theta) * cos(phi), sin(phi) ]
        self.vecLight = Vector(cos(angleRad) * cos(elevationRad), sin(angleRad) * cos(elevationRad), sin(elevationRad))

        // Viewer azimuth, phi2 = average between phi and pi/2
        let phi2 = (_NC.PI12 + elevationRad) / 2.0
        self.vecAzimuth = Vector(cos(angleRad) * sin(phi2), sin(angleRad) * sin(phi2), cos(phi2))
        
        // Light vector for simple shading
        self.vecSimple = Vector(cos(angleRad), sin(angleRad), 0)
        
        // Height factor of the incoming light for simple shading (45 degrees: 1 + 45 / 90 = 1.5)
        height = 1.0 + Double(elevation) / 90.0
    }
    
    ///
    /// Simple shading
    ///
    /// Parameters:
    ///
    /// normal: Normal vector
    ///
    /// Return brightness in range 0..1
    ///
    func simple3D(_ normal: Vector) -> Double {
        let diffuseLight = mulDot(normal, vecSimple) + height
        return diffuseLight / (1.0 + height)
    }
    
    ///
    /// Blinn-Phong-Shading
    /// Calculation is done with double precision
    ///
    /// Parameters:
    ///
    /// normal: Normal vector
    ///
    /// Return brightness in range 0..1
    ///
    func blinnPhong(_ normal: Vector) -> Double {
        // diffuse light = dotproduct(light, normal)
        var diffuseLight = mulDot(normal, vecLight)
        // Normalization
        diffuseLight /= (1 + vecLight[2])
        
        // specular light = dotproduct(azimuth, normal)
        var specularLight = mulDot(normal, vecAzimuth)
        // Normalization
        specularLight = specularLight / (1 + vecAzimuth[2])
        
        // Shininess
        specularLight = pow(specularLight, shininess)
        
        // Brightness = ambient light + diffuse light + specular light
        var brightness = ambient + diffuse * diffuseLight + specular * specularLight
        
        // Add intensity
        brightness = brightness * opacity + (1 - opacity) / 2
        
        return brightness
    }
}
