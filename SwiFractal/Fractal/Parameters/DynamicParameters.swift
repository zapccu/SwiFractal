//
//  MandelbrotDynamicParameters.swift
//  SwiFractal
//
//  Created by Dirk Braner on 21.03.26.
//

import Foundation
import Accelerate
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
    let resolution: CGSize
    
    // Pre-calculated bailout values
    let logBailout: Double           // log(bailout)
    let div_logBailout_2: Double     // 0.5 * log(bailout)
    let div_2_logBailout: Double     // 2.0 / log(bailout)
    let div_05_logBailout: Double    // 0.5 / log(bailout)
    
    // Scaling for orbit coloring inside Mandelbrot set
    let diaScale: Double             // diaScale = iterations / 10
    
    // Distance normalization factor
    let diag: RT                     // diag = 1 / abs(size)
    
    // Flags
    var bStripes: Bool,              // Calculate stripes
        bSteps: Bool,                // Calculate steps
        bDist: Bool,                 // Calculate distance to Mandelbrot set
        bOrbits: Bool,               // Draw orbits
        bShading: Bool,              // Either simple3D or blinnPhong
        bFilaments: Bool             // Draw filaments
    
    // Lighning
    let lightning: Lightning         // Lightning depends on LightningParameters
    
    // Pixelsize
    let dx: RT
    let dy: RT
    
    // Array with potential values: potential[n] = 1/2^n, n=0..<iterations
    var potential: [Double] = []
    
    /// Provide direct access to static fractal parameters
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
    
    /// Initialize dynamic calculation parameters
    /// - Parameters:
    ///   - anypar: Static fractal parameters
    ///   - resolution: Image resolution without oversampling
    init(anypar: PT, resolution: CGSize) {
        let p = anypar.dimensions.precision.bits

        self.fractalParameters = anypar
        self.resolution = resolution

        let sx = anypar.dimensions.sizeX
        let sy = anypar.dimensions.sizeY
        
        (dx, dy) = anypar.dimensions.pixelDistance(resolution: resolution)

        logBailout        = log(anypar.limits.bailout)
        div_logBailout_2  = 0.5 * logBailout
        div_2_logBailout  = 2.0 / logBailout
        div_05_logBailout = 0.5 / logBailout
        
        diaScale = Double(anypar.limits.iterations) / 10.0
        diag     = RT(1.0, precision: p) / RT.sqrt(sx * sx + sy * sy)

        // Flags
        bStripes   = anypar.coloring.stripes > 0
        bSteps     = anypar.coloring.steps > 0
        bOrbits    = anypar.coloring.colorizeInside == .orbits
        bDist      = bStripes || bSteps || anypar.coloring.colorizeMode == .distance
        bShading   = bStripes || bSteps || anypar.coloring.colorizeOutside.isAny(of: [.simple3d, .blinnPhong])
        bFilaments = anypar.coloring.colorizeOutside == .filaments
        
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
    
}
