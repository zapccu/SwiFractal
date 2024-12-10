//
//  Lightning.swift
//  SwiFractal
//
//  Created by Dirk Braner on 09.12.24.
//

import Numerics
import simd


//
// Lightning parameters and methods
//
struct Lightning {
    var angle: Double
    var elevation: Double
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
    
    /// Initialize lightning object
    ///
    /// Parameters:
    ///
    /// dict: Dictionary with lightning settings
    ///
    init(_ dict: DictPar = [:]) {
        angle     = dict["angle", 45.0]
        elevation = dict["elevation", 45.0]
        opacity   = dict["opacity", 0.75]
        ambient   = dict["ambient", 0.2]
        diffuse   = dict["diffuse", 0.5]
        specular  = dict["specular", 0.5]
        shininess = dict["shininess", 20.0]
        gamma     = dict["gamma", 1.0]
        
        let angleRad     = deg2rad(angle)
        let elevationRad = deg2rad(elevation)

        // angle = theta, elevation = phi
        self.vecLight = Vector(cos(angleRad) * cos(elevationRad), sin(angleRad) * cos(elevationRad), sin(elevationRad))

        // Viewer azimuth, phi2 = average between phi and pi/2
        let phi2 = (Double.pi / 2 + elevationRad) / 2
        self.vecAzimuth = Vector(cos(angleRad) * sin(phi2), sin(angleRad) * sin(phi2), cos(phi2))
        
        // 2D Light vector for simple shading
        self.vecSimple = Vector(cos(angleRad), sin(angleRad), 0)
        
        // Height factor of the incoming light for simple shading (1.5 = 45 degrees)
        height = 1 + elevation / 90.0
    }
    
    /// Convert complex number to vector
    ///
    func CplxToVector(_ c: Cplx) -> Vector {
        let v = c / Cplx(c.length)
        return Vector(v.real, v.imaginary, 1)
    }
    
    /// Simple shading
    ///
    /// Parameters:
    ///
    /// normal: Normal vector
    ///
    /// Return brightness in range 0..1
    ///
    func simple3D(_ normal: Vector) -> Double {
        let diffuseLight = simd_dot(normal, vecSimple)
        return diffuseLight / (1 + height)
    }
    
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
        var diffuseLight = simd_dot(normal, vecLight)
        
        // Normalization
        diffuseLight = diffuseLight / (1 + vecLight[2])
        
        // specular light = dotproduct(phi2, normal)
        var specularLight = simd_dot(normal, vecAzimuth)
        
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
