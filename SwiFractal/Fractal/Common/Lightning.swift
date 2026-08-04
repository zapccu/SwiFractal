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
// Lightning
//
@dynamicMemberLookup
struct Lightning {
    
    let parameters: LightningParameters
    
    // Vectors for Blinn-Phong-Shading
    var angleRad: Double
    var elevationRad: Double
    var vecLight: Vector<Double>
    var vecAzimuth: Vector<Double>
    
    // Vector and height factor for simple shading
    var vecSimple: Vector<Double>
    var height: Double
    
    /// Direct access to LightningParameters
    subscript<V>(dynamicMember keyPath: WritableKeyPath<LightningParameters, V>) -> V {
        get { parameters[keyPath: keyPath] }
    }
    
    /// Initialize lightning object
    /// - Parameter parameters: Struct with lightning parameters
    init(_ parameters: LightningParameters) {
        
        self.parameters = parameters
        
        // Convert angles from degree to rad
        self.angleRad     = deg2rad(Double(parameters.angle))
        self.elevationRad = deg2rad(Double(parameters.elevation))
        
        // angle = theta, elevation = phi
        // light vector = [ cos(theta) * cos(phi), sin(theta) * cos(phi), sin(phi) ]
        self.vecLight = Vector<Double>([cos(angleRad) * cos(elevationRad), sin(angleRad) * cos(elevationRad), sin(elevationRad)])

        // Viewer azimuth, phi2 = average between phi and pi/2
        let phi2 = (_NC.PI12 + elevationRad) / 2.0
        self.vecAzimuth = Vector<Double>([cos(angleRad) * sin(phi2), sin(angleRad) * sin(phi2), cos(phi2)])
        
        // Light vector for simple shading
        self.vecSimple = Vector<Double>([cos(angleRad), sin(angleRad), 0])
        
        // Height factor of the incoming light for simple shading (45 degrees: 1 + 45 / 90 = 1.5)
        height = 1.0 + Double(parameters.elevation) / 90.0
    }
    
    /// Simple shading
    /// - Parameter normal: Normal vector
    /// - Returns: brightness in range 0-1
    func simple3D(_ normal: Vector<Double>) -> Double {
        let diffuseLight = normal * vecSimple + height
        return diffuseLight / (1.0 + height)
    }
    
    /// Blinn-Phong-Shading
    /// Calculation is done with double precision
    /// - Parameter normal: Normal vector
    /// - Returns: brightness in range 0-1
    func blinnPhong(_ normal: Vector<Double>) -> Double {
        
        // Calculate diffuse light
        //
        // theta: light angle
        // phi:   light azimuth
        //
        // light_vector  = [cos(theta)cos(phi), sin(theta)cos(phi), sin(phi)]
        // normal_vector = [normal.real, normal.imag, 1]
        //
        // diffuseLight  = dot product(light_vector, normal_vector)
        var diffuseLight = normal * vecLight
        // Normalization
        diffuseLight /= (1 + vecLight[2])
        
        // Calculate specular light
        //
        // phi2:  average between phi and pi/2 (viewer azimuth)
        //
        // specularLight = dot product(phi2, normal)
        var specularLight = normal * vecAzimuth
        // Normalization
        specularLight = specularLight / (1 + vecAzimuth[2])
        
        // Shininess
        specularLight = pow(specularLight, parameters.shininess)
        
        // Brightness = ambient light + diffuse light + specular light
        var brightness = parameters.ambient + parameters.diffuse * diffuseLight + parameters.specular * specularLight
        
        // Add intensity
        brightness = brightness * parameters.opacity + (1 - parameters.opacity) / 2
        
        return brightness
    }
}
