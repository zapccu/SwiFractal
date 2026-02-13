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

struct MandelbrotComputeParameters {
    var iterations: Int32
    var colors: Int32
    var bDist: Int32
    var bShading: Int32
    var bStripes: Int32
    var bPotential: Int32
    var colorizeMode: Int32
    var paletteMode: Int32
    var ncycle: Int32
    var bailout: Float2
    var stripes: Float2
    var stripeSig: Float2
    var steps: Float2
    var diag: Float2
}


//
// Class for Mandelbrot calculation parameters
//

class MandelbrotParameters: FractalParameters {
    
    // Constant parameters
    var iterations: Int,
        stripes: Int,                   // Stripe density
        stripeSig: Double,
        steps: Int,                     // Step density
        colorMapping: ColorMapping

    // Parameters calculated or modified based on constant parameters
    var bailout: Double,                // Bailout radius
        logBailout: Double,             // Logarithm of bailout radius
        ncycle: Double,
        diaScale: Double
    
    // Flags
    var bStripes: Bool,                 // Draw stripes
        bSteps: Bool,                   // Draw steps
        bDist: Bool,                    // Calculate distance to Mandelbrot set
        bOrbits: Bool,                  // Draw orbits
        bShading: Bool,                 // Either simple3D or blinnPhong
        bHist: Bool                     // Calculate histogram for color mapping
    
    /// Return Metal compute parameters
    var computeParameters: MandelbrotComputeParameters {
        return MandelbrotComputeParameters(
            iterations: Int32(iterations),
            colors: Int32(colorMapping.palette.count),
            bDist: bDist ? 1 : 0,
            bShading: bShading ? 1 : 0,
            bStripes: bStripes ? 1 : 0,
            bPotential: colorMapping.colorizeMode == .potential ? 1 : 0,
            colorizeMode: Int32(colorMapping.colorizeMode.rawValue),
            paletteMode: Int32(colorMapping.paletteMode.rawValue),
            ncycle: Int32(ncycle),
            bailout: Float2(bailout),
            stripes: Float2(stripes),
            stripeSig: Float2(stripeSig),
            steps: Float2(steps),
            diag: Float2(diag)
        )
    }
    
    /// Initialize Mandelbrot calculation parameters
    ///
    /// Parameters:
    ///
    /// parameterset: Mandelbrot parameterset
    ///
    override init(_ parameterset: ParameterSet = ParameterSet()) {
        
        // Constant parameters
        iterations   = parameterset["Mandelbrot.iterations", default: 500]
        stripes      = parameterset["Mandelbrot.stripes", default: 0]
        stripeSig    = 0.9
        steps        = parameterset["Mandelbrot.steps", default: 0]
        ncycle       = parameterset["Mandelbrot.ncycle", default: 1]
        colorMapping = ColorMapping(parameterset["Mandelbrot"])

        // Dynamoc parameters
        bailout    = 1e10
        logBailout = log(bailout)
        ncycle     = sqrt(ncycle)
        diaScale   = Double(iterations) / 10.0
        
        // Flags
        bStripes = stripes > 0
        bSteps   = steps > 0
        bOrbits = colorMapping.colorizeInside == .orbits
        bDist    = colorMapping.colorizeMode == .distance || bStripes || bSteps
        bShading = colorMapping.colorizeOutside.isAny(of: [.simple3d, .blinnPhong])
        bHist    = colorMapping.paletteMode == .histogram
        
        // Stripes and steps require shading
        if (bStripes || bSteps) && !bShading {
            colorMapping.colorizeOutside = ColorizeOutside(.blinnPhong)
            bShading = true
        }
        
        // Initialize common fractal calculation parameters
        super.init(parameterset)

    }

}

