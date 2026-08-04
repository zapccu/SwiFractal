//
//  MandelbrotDynamicParameters.swift
//  SwiFractal
//
//  Created by Dirk Braner on 21.03.26.
//

import Foundation
import Accelerate
import ParSetKit
import SwiftMPx


//
// Dynamic Mandelbrot calculation parameters
//
@dynamicMemberLookup
struct DynamicParameters<PT: FractalData> : PrDynamicParameters {

    typealias RT = PT.RT
    
    //static var output: Bool = false
    
    // Parameters copied from static parameters
    // Prevent performance issues because of observable fractal parameters
    let fractalParameters: PT
    
    // Image dimensions without oversampling
    var resolution: CGSize
    
    // Pre-calculated bailout values
    var logBailout: Double              // log(bailout)
    var div_logBailout_2: Double        // 0.5 * log(bailout)
    var div_2_logBailout: Double        // 2.0 / log(bailout)
    var div_05_logBailout: Double       // 0.5 / log(bailout)
    
    // Scaling for orbit coloring inside Mandelbrot set
    var diaScale: Double                // diaScale = iterations / 10
    
    // Distance normalization factor
    var diag: RT                        // diag = 1 / abs(size)
    
    // Flags
    var bStripes: Bool,                 // Draw stripes
        bSteps: Bool,                   // Draw steps
        bDist: Bool,                    // Calculate distance to Mandelbrot set
        bOrbits: Bool,                  // Draw orbits
        bShading: Bool,                 // Either simple3D or blinnPhong
        bFilaments: Bool                // Draw filaments
    
    // Lighning
    var lightning: Lightning
    
    // Pixelsize
    let dx: RT
    let dy: RT
    
    // Array with potential values: potential[n] = 1/2^n, n=0..<iterations
    var potential: [Double] = []
    
    // Count orbits found during calculation
    var orbitCount: Int = 0
    
    /// Direct access to mandelbrotParameters
    subscript<V>(dynamicMember keyPath: WritableKeyPath<PT, V>) -> V {
        get { fractalParameters[keyPath: keyPath] }
    }
    
    /// Return Metal compute parameters
    var computeParameters: MetalComputeParameters {
        MetalComputeParameters(
            iterations: Int32(fractalParameters.limits.iterations),
            colors: Int32(fractalParameters.coloring.colorTable.ct.count),
            bDist: bDist ? 1 : 0,
            bShading: bShading ? 1 : 0,
            bStripes: bStripes ? 1 : 0,
            bPotential: fractalParameters.coloring.colorizeMode == .potential ? 1 : 0,
            colorizeMode: Int32(fractalParameters.coloring.colorizeMode.rawValue),
            paletteMode: Int32(fractalParameters.coloring.paletteMode.rawValue),
            ncycle: Int32(fractalParameters.coloring.ncycle),
            bailout: Float2(fractalParameters.limits.bailout),
            stripes: Float2(fractalParameters.coloring.stripes),
            stripeSig: Float2(fractalParameters.coloring.stripeSig),
            steps: Float2(fractalParameters.coloring.steps),
            diag: Float2(diag.toDouble())
        )
    }
    
    init(anypar: PT, resolution: CGSize) {
        let p = anypar.dimensions.precision.bits

        self.fractalParameters = anypar
        self.resolution = resolution
        let sx = anypar.dimensions.sizeX
        let sy = anypar.dimensions.sizeY
        
        dx = sx / RT(resolution.width - 1, precision: p)
        dy = sy / RT(resolution.height - 1, precision: p)
        
        logBailout = log(anypar.limits.bailout)
        
        div_logBailout_2  = 0.5 * logBailout
        div_2_logBailout  = 2.0 / logBailout
        div_05_logBailout = 0.5 / logBailout
        
        diaScale = Double(anypar.limits.iterations) / 10.0
        diag     = RT(1.0, precision: p) / RT.sqrt(sx * sx + sy * sy)

        // Flags
        bStripes = anypar.coloring.stripes > 0
        bSteps   = anypar.coloring.steps > 0
        bOrbits  = anypar.coloring.colorizeInside == .orbits
        bDist    = bStripes || bSteps || anypar.coloring.colorizeMode == .distance
        bShading = bStripes || bSteps || anypar.coloring.colorizeOutside.isAny(of: [.simple3d, .blinnPhong])
        bFilaments = false
        
        // Lightning
        lightning = Lightning(anypar.lightParameters)
        
        // Potential lookup table
        var pot: Double = 1.0
        potential = Array(repeating: 0.0, count: anypar.limits.iterations+1)
        for i in 0..<anypar.limits.iterations+1 {
            potential[i] = pot
            pot *= 0.5
        }
    }
    
    /// Initialize dynamic Mandelbrot parameters
    /// - Parameters:
    ///   - parameters: Mandelbrot parameters
    /*
    init?(parameters: MandelbrotParameters<RT>, resolution: CGSize) {
        let p = parameters.dimensions.precision.bits
        
        self.parameters = parameters
        
        self.resolution = resolution
        
        let sx = parameters.dimensions.sizeX
        let sy = parameters.dimensions.sizeY
        
        dx = sx / RT(resolution.width - 1, precision: p)
        dy = sy / RT(resolution.height - 1, precision: p)
        
        logBailout        = log(parameters.limits.bailout)
        div_logBailout_2  = 0.5 * logBailout
        div_2_logBailout  = 2.0 / logBailout
        div_05_logBailout = 0.5 / logBailout
        
        diaScale = Double(parameters.limits.iterations) / 10.0
        diag     = RT(1.0, precision: p) / RT.sqrt(sx * sx + sy * sy)

        // Flags
        bStripes = parameters.coloring.stripes > 0
        bSteps   = parameters.coloring.steps > 0
        bOrbits  = parameters.coloring.colorizeInside == .orbits
        bDist    = bStripes || bSteps || parameters.coloring.colorizeMode == .distance
        bShading = bStripes || bSteps || parameters.coloring.colorizeOutside.isAny(of: [.simple3d, .blinnPhong])
        bFilaments = false
        
        // Lightning
        lightning = Lightning(parameters.lightParameters)
        
        // Potential lookup table
        var pot: Double = 1.0
        potential = Array(repeating: 0.0, count: limits.iterations+1)
        for i in 0..<limits.iterations+1 {
            potential[i] = pot
            pot *= 0.5
        }
    }
     */
    /*
    func mapScreenCoordinates(aspectRatio: Bool = true) -> Matrix<CT> {
        let newDimensions = aspectRatio ? fractalParameters.dimensions.adjustAspectRatio(resolution: resolution) : fractalParameters.dimensions
        return Matrix<CT>((osImageHeight, osImageWidth), start: newDimensions.corner, end: newDimensions.corner + newDimensions.size)
    }
    
    func mapScreenCoordinates(refPoint: CT, aspectRatio: Bool = true) -> Matrix<CT> {
        let newDimensions = aspectRatio ? dimensions.adjustAspectRatio(resolution: resolution) : dimensions
        let startDelta = newDimensions.corner - refPoint
        let endDelta   = refPoint + startDelta
        return Matrix<CT>((osImageHeight, osImageWidth), start: startDelta, end: endDelta)
    }
     */
    
}
