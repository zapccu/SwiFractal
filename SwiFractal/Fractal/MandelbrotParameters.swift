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

// MUST BE UPATED
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
    
    //
    // Constant parameters
    //
    
    var iterations: Int                 // Maximum number of iterations. default = 500
    var bailout: Double                 // Bailout radius. default = 1e10
    
    var stripes: Int                    // Stripe density, frequency for stripe average coloring
                                        // Range 0-32, 0 = No stripes, default = 0
    var stripeSig: Double               // Memory parameter for stripe average coloring
                                        // Range 0-1, 0 = No stripes, default = 0.9
    
    var steps: Int                      // Step density, frequency for step coloring
                                        // Range 0-100, 0 = No steps, default = 0
    
    var orbitDelta1: Double             // Orbit detection: 1st delta = 1e-15
    var orbitDelta2: Double             // Orbit detection: 2nd delta = 1e-11
    var orbitDelta3: Double             // Orbit detection: delta for fast detection = 1e-10
    var orbitLength: Int                // Limit for fast orbit detection = 20
    
    var colorMapping: ColorMapping      // ColorMapping object

    //
    // Parameters calculated or modified based on constant parameters
    //
    
    var logBailout: Double              // Logarithm of bailout radius
                                        // logBailout = log(bailout)
    var logBailout2: Double             // log2Bailout = 2 / log(bailout)
    var ncycle: Double                  // Number of iteration before cycling the colortable
                                        // Range 1-200, 1 = No cycling, default = 1
    var diaScale: Double                // Scaling for orbit coloring inside Mandelbrot set
                                        // diaScale = iterations / 10
    //var diag: Double                    // Distance normalization factor
                                        // diag = 1 / abs(size)
    
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
        bailout      = 1e10
        stripes      = parameterset["Mandelbrot.stripes", default: 0]
        stripeSig    = 0.9
        steps        = parameterset["Mandelbrot.steps", default: 0]
        ncycle       = parameterset["Mandelbrot.ncycle", default: 1.0]
        orbitDelta1  = 1e-15
        orbitDelta2  = 1e-11
        orbitDelta3  = 1e-10
        orbitLength  = 20
        colorMapping = ColorMapping("Mandelbrot", parameterset)

        // Dynamic parameters
        logBailout  = log(bailout)
        logBailout2 = logBailout * 2.0
        ncycle      = sqrt(ncycle)
        diaScale    = Double(iterations) / 10.0
        //diag        = 1.0 / size.length
        
        // Flags
        bStripes = stripes > 0
        bSteps   = steps > 0
        bOrbits  = colorMapping.colorizeInside == .orbits
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

