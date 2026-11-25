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


///
/// Implement lightning.
/// Lightning struct is created from LigthningParameters.
///
@dynamicMemberLookup
struct Lightning {
    
    /// Lightning parameters
    let parameters: LightningParameters
    
    /// Viewer angle in radian
    let angleRad: Double
    
    /// Elevation angle in radian
    let elevationRad: Double
    
    /// Exposure factor = pow(2, ev)
    let exposure: Float
    
    /// Light vector for Blinn-Phong-Shading
    let vecLight: Vector3<Double>
    
    /// Azimuth vector for Blinn-Phong-Shading
    let vecAzimuth: Vector3<Double>
    
    /// Vector for simple shading
    let vecSimple: Vector3<Double>
    
    /// Precalculate diffuse factor for normal vector
    let diffuseLightVector: Vector3<Double>
    
    /// Precalculate specular factor for normal vector
    let specularLightVector: Vector3<Double>
    
    /// Height factor for simple shading
    let height: Double
    
    /// Direct access to LightningParameters
    subscript<V>(dynamicMember keyPath: WritableKeyPath<LightningParameters, V>) -> V {
        get { parameters[keyPath: keyPath] }
    }
    
    /// Initialize lightning object
    /// - Parameter parameters: Struct with lightning parameters
    init(_ parameters: LightningParameters) {
        
        self.parameters = parameters
        
        // Convert angles from degree to rad
        self.angleRad     = Double(parameters.angle).deg2rad
        self.elevationRad = Double(parameters.elevation).deg2rad
        
        // Calculate exposure factor
        self.exposure = pow(2.0, Float(parameters.ev))
        
        // angle = theta, elevation = phi
        // light vector = [ cos(theta) * cos(phi), sin(theta) * cos(phi), sin(phi) ]
        self.vecLight = Vector3<Double>(x: cos(angleRad) * cos(elevationRad), y: sin(angleRad) * cos(elevationRad), z: sin(elevationRad))
        
        // Precalculate diffuse light vector for normal vector
        self.diffuseLightVector = self.vecLight / (1.0 + self.vecLight[2])
        
        // Viewer azimuth, phi2 = average between phi and pi/2
        let phi2 = (_NC.PI12 + elevationRad) / 2.0
        self.vecAzimuth = Vector3<Double>(x: cos(angleRad) * sin(phi2), y: sin(angleRad) * sin(phi2), z: cos(phi2))
        
        // Precalculate specular light vector for normal vector
        self.specularLightVector = vecAzimuth / (1.0 + vecAzimuth[2])

        // Light vector for simple shading
        self.vecSimple = Vector3<Double>(x: cos(angleRad), y: sin(angleRad), z: 0)
        
        // Height factor of the incoming light for simple shading (45 degrees: 1 + 45 / 90 = 1.5)
        height = 1.0 + Double(parameters.elevation) / 90.0
    }
    
    /// Simple shading
    /// - Parameter normal: Normal vector
    /// - Returns: brightness value greater than or equal to 0.0
    func simple3D(_ normal: Vector3<Double>) -> Float {
        let diffuseLight = normal.dot(vecSimple) + height
        let brightness = diffuseLight / (1.0 + height)
        return Float(max(brightness, 0.0))
    }
    
    /// Blinn-Phong-Shading
    /// Calculation is done with double precision
    /// - Parameters:
    ///   - normal: Normal vector
    ///   - blending: Blending mode. Default is .multiply
    /// - Returns: brightness value greater than or equal to 0.0
    func blinnPhong(_ normal: Vector3<Double>, blending: BlendingMode = .multiply) -> Float {
        
        // Calculate diffuse light
        //
        // theta: light angle
        // phi:   light azimuth
        //
        // light_vector  = [cos(theta)*cos(phi), sin(theta)*cos(phi), sin(phi)]
        // normal_vector = [normal.real, normal.imag, 1]
        //
        // 1. diffuseLight  = dot product(light_vector, normal_vector)
        // 2. Normalization: diffuseLight /= (1.0 + vecLight[2])
        let diffuseLight = normal.dot(diffuseLightVector)

        // Calculate specular light
        //
        // phi2: average between phi and pi/2 (viewer azimuth)
        //
        // 1. specularLight = dot-product(phi2, normal)
        // 2. Normalization: specularLight /= (1.0 + vecAzimuth[2])
        var specularLight = max(normal.dot(specularLightVector), 0.0)
        
        // Shininess
        specularLight = pow(specularLight, parameters.shininess)
        
        // Brightness = ambient light + diffuse light + specular light
        var brightness = parameters.ambient + parameters.diffuse * diffuseLight + parameters.specular * specularLight
        
        // Add intensity
        brightness = blending == .hardLight
            ? brightness * parameters.opacity + (1 - parameters.opacity) * 0.5
            : brightness * parameters.opacity + (1 - parameters.opacity)
        
        return Float(max(brightness, 0.0))
    }
    
}
