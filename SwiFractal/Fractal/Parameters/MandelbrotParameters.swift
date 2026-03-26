//
//  MandelbrotParameters.swift
//  SwiFractal
//
//  Created by Dirk Braner on 13.02.26.
//

//
// Transfer structure for Metal compute parameters
//

import Foundation



// Static Mandelbrot calculation parameters
struct MandelbrotParameters : FractalData {
    
    // Data type name
    static let dataType: String = "MandelbrotParameters"
    
    // Default values
    static let defaultValues: [String: Any] = [
        "common":           CommonParameters.defaultValues as [String : Any],
        "iterations":       200 as Int,
        "bailout":          1e10 as Double,
        "orbitDelta1":      1e-15 as Double,
        "orbitDelta2":      1e-11 as Double,
        "orbitDelta3":      1e-10 as Double,
        "orbitLength":      20 as Int,
        "colorMapping":     ColorMapping.defaultValues as [String : Any]
    ]
    
    // Default data structure
    static let defaultData = MandelbrotParameters()
    
    // Common parameters
    var common = CommonParameters()
    
    // Mandelbrot specific parameters
    var iterations: Int = 200                // Maximum number of iterations. default = 200
    var bailout: Double = 1e10                // Bailout radius. default = 1e10
    
    var orbitDelta1: Double = 1e-15             // Orbit detection: 1st delta = 1e-15
    var orbitDelta2: Double = 1e-11            // Orbit detection: 2nd delta = 1e-11
    var orbitDelta3: Double = 1e-10            // Orbit detection: delta for fast detection = 1e-10
    var orbitLength: Int = 20                // Limit for fast orbit detection = 20
    
    var colorMapping: ColorMapping = ColorMapping()     // ColorMapping object
    
    var cplxCorner: Cplx {
        get { Cplx(common.nCornerX, common.nCornerY) }
        set { }
    }
    var cplxSize: Cplx {
        get { Cplx(common.nSizeX, common.nSizeY) }
        set { }
    }
}


