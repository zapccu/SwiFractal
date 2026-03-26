//
//  MandelbrotDynamicParameters.swift
//  SwiFractal
//
//  Created by Dirk Braner on 21.03.26.
//

import Foundation
import ParSetKit

//
// Dynamic Mandelbrot calculation parameters
//
struct MandelbrotDynamicParameters : DynamicParameters {
    
    // Parameters copied from static parameters
    // Prevent performance issues because of observable fractal parameters
    let MP: MandelbrotParameters

    // Bailout values
    var logBailout: Double              // logBailout = log(bailout)
    var logBailout2: Double             // logBailout2 = 0.5 * log(bailout)
    var log2Bailout: Double             // log2Bailout = 2.0 * log(bailout)
    
    // Scaling for orbit coloring inside Mandelbrot set
    var diaScale: Double                // diaScale = iterations / 10
    
    // Distance normalization factor
    var diag: Double                    // diag = 1 / abs(size)
    
    // Flags
    var bStripes: Bool,                 // Draw stripes
        bSteps: Bool,                   // Draw steps
        bDist: Bool,                    // Calculate distance to Mandelbrot set
        bOrbits: Bool,                  // Draw orbits
        bShading: Bool,                 // Either simple3D or blinnPhong
        bHist: Bool                     // Calculate histogram for color mapping
    
    // Lighning
    var lightning: Lightning
        
    // 2 dimensional array with complex coordinates
    var cplxGrid: [[Cplx]] = []
    
    // 2 dimensional array with number of iterations per pixel (index = y, x)
    var iterationCountPerPixel: [[Int]] = []
    
    // Array with number of pixels with iteration count (index = iteration count)
    var pixelCountPerIteration: [Int] = []
    
    // Count orbits found during calculation
    var orbitCount: Int = 0
    
    /// Return Metal compute parameters
    var computeParameters: MandelbrotComputeParameters
    
    /// Initialize dynamic Mandelbrot parameters
    init(parameters: MandelbrotParameters, imageWidth: Int, imageHeight: Int) {
        MP = parameters
        
        logBailout  = log(parameters.bailout)
        logBailout2 = 0.5 * logBailout
        log2Bailout = 2.0 * logBailout
        diaScale    = Double(parameters.iterations) / 10.0
        diag        = 1.0 / sqrt(parameters.common.nSizeX * parameters.common.nSizeX + parameters.common.nSizeY * parameters.common.nSizeY)

        // Flags
        bStripes = parameters.colorMapping.stripes > 0
        bSteps   = parameters.colorMapping.steps > 0
        bOrbits  = parameters.colorMapping.colorizeInside == .orbits
        bDist    = parameters.colorMapping.colorizeMode == .distance || bStripes || bSteps
        bShading = parameters.colorMapping.colorizeOutside.isAny(of: [.simple3d, .blinnPhong])
        bHist    = parameters.colorMapping.paletteMode == .histogram
        
        // Lightning
        lightning = Lightning(parameters.common.lightning)
        
        // Stripes and steps require shading
        if bStripes || bSteps {
            bShading = true
        }
        
        computeParameters = MandelbrotComputeParameters(
            iterations: Int32(parameters.iterations),
            colors: Int32(parameters.colorMapping.palette.count),
            bDist: bDist ? 1 : 0,
            bShading: bShading ? 1 : 0,
            bStripes: bStripes ? 1 : 0,
            bPotential: parameters.colorMapping.colorizeMode == .potential ? 1 : 0,
            colorizeMode: Int32(parameters.colorMapping.colorizeMode.rawValue),
            paletteMode: Int32(parameters.colorMapping.paletteMode.rawValue),
            ncycle: Int32(parameters.colorMapping.ncycle),
            bailout: Float2(parameters.bailout),
            stripes: Float2(parameters.colorMapping.stripes),
            stripeSig: Float2(parameters.colorMapping.stripeSig),
            steps: Float2(parameters.colorMapping.steps),
            diag: Float2(diag)
        )
        
        mapScreenCoordinates(imageWidth, imageHeight, corner: parameters.cplxCorner, size: parameters.cplxSize)
        
        if bHist {
            iterationCountPerPixel = Array(repeating: Array<Int>(repeating: 0, count: imageHeight), count: imageWidth)
            pixelCountPerIteration = Array<Int>(repeating: 0, count: parameters.iterations)
        }
    }
    
    /// Adjust complex area to consider aspect ratio of drawing area
    func adjustAspectRatio(_ imageWidth: Int, _ imageHeight: Int, _ corner: Cplx, _ size: Cplx) -> (corner: Cplx, size: Cplx) {
        let imageRatio = Double(imageWidth) / Double(imageHeight)
        let fractalRatio = size.real / size.imaginary
        
        if imageRatio != fractalRatio {
            let fractalHeight = size.real / imageRatio
            let newCorner = Cplx(corner.real, corner.imaginary + (size.imaginary - fractalHeight) / 2)
            let newSize = Cplx(size.real, fractalHeight)
            return (newCorner, newSize)
        }
        
        return (corner, size)
    }
    
    /// Create matrix of complex values representing the pixels of the drawing area
    mutating func mapScreenCoordinates(_ imageWidth: Int, _ imageHeight: Int, corner: Cplx, size: Cplx, aspectRatio: Bool = true) {
        var c = corner
        var s = size
        
        if aspectRatio {
            (c, s) = adjustAspectRatio(imageWidth, imageHeight, c, s)
        }

        cplxGrid = linspace(c, c + s, imageWidth, imageHeight)
    }
    
}
