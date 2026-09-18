//
//  MandelbrotDynamicParameters.swift
//  SwiFractal
//
//  Created by Dirk Braner on 21.03.26.
//

import Foundation
import Accelerate
import SwiftMPx
import Metal64


//
// Dynamic Mandelbrot calculation parameters
//
nonisolated struct DynamicParameters<PT: FractalData> {

    typealias RT = PT.RT
    
    //static var output: Bool = false
    
    /// Snapshot of application settings
    let settings: SettingsSnapshot
    
    /// Parameters copied from static parameters.
    /// Prevent performance issues because of observable fractal parameters
    let fp: PT
    
    /// Mantissa precision bits
    let precision: Int
    
    /// Number of points to skip
    let skip: Int
        
    /// Image dimensions without oversampling
    let resolution: CGSize
    
    /// Image width without oversampling
    let imageWidth: Int
    
    /// Image height without oversampling
    let imageHeight: Int
    
    /// Image width considering oversampling
    let osImageWidth: Int
    
    /// Image height considering oversampling
    let osImageHeight: Int
    
    /// Image size considering oversampling
    let osSize: ISize
    
    /// Pre-calculated bailout values
    let logBailout: Double           // log(bailout)
    let div_logBailout_2: Double     // 0.5 * log(bailout)
    let div_2_logBailout: Double     // 2.0 / log(bailout)
    let div_05_logBailout: Double    // 0.5 / log(bailout)
    
    /// Scaling for orbit coloring inside Mandelbrot set
    let diaScale: Double             // diaScale = iterations / 10
    
    /// Distance normalization factor
    let diag: RT                     // 1 / abs(size)
    
    /// Threshold for filament calculation
    let distThreshold: RT            // pixelDistance * 0.5
    
    // Flags
    var bStripes: Bool,              // Calculate stripes
        bSteps: Bool,                // Calculate steps
        bDist: Bool,                 // Calculate distance to Mandelbrot set
        bOrbits: Bool,               // Draw orbits
        bShading: Bool,              // Either simple3D or blinnPhong
        bFilaments: Bool             // Draw filaments
    
    /// Lightning
    let lightning: Lightning         // Lightning depends on LightningParameters
    
    /// Array with potential values: potential[n] = 1/2^n, n=0..<iterations
    var potential: [Double] = []
    
    /// Return Metal compute parameters
    var computeParameters: MetalComputeParameters {
        MetalComputeParameters(
            iterations: Int32(fp.limits.iterations),
            bStripes: bStripes ? 1 : 0,
            bailout: Float(fp.limits.bailout),
            logBailout: Float2(logBailout),
            div_2_logBailout: Float2(div_2_logBailout),
            stripes: Float2(fp.colorParameters.stripes),
            stripeSig: Float2(fp.colorParameters.stripeSig),
            steps: Float2(fp.colorParameters.steps),
            diag: Float2(diag.asDouble),
            distThreshold: Float2(distThreshold.asDouble)
        )
    }
    
    /// Initialize dynamic calculation parameters
    /// - Parameters:
    ///   - anypar: Static fractal parameters
    ///   - resolution: Image resolution without oversampling
    ///   - settings: Snapshot of application settings
    init(anypar: PT, resolution: CGSize, settings: SettingsSnapshot) {
        self.settings = settings
        
        self.precision = anypar.dimensions.precision.bits
        
        self.skip = 0

        self.fp = anypar
        
        self.resolution = resolution
        self.imageWidth  = Int(resolution.width)
        self.imageHeight = Int(resolution.height)
        self.osImageWidth = Int(resolution.width) * anypar.dimensions.oversampling
        self.osImageHeight = Int(resolution.height) * anypar.dimensions.oversampling
        self.osSize = ISize(width: osImageWidth, height: osImageHeight)

        let (dx, dy) = anypar.dimensions.pixelDistance(resolution: resolution)
        self.distThreshold = min(dx, dy) * 0.5

        self.logBailout        = log(anypar.limits.bailout)
        self.div_logBailout_2  = 0.5 * logBailout
        self.div_2_logBailout  = 2.0 / logBailout
        self.div_05_logBailout = 0.5 / logBailout
        
        let sx = anypar.dimensions.sizeX
        let sy = anypar.dimensions.sizeY
        self.diaScale = Double(anypar.limits.iterations) / 10.0
        self.diag     = RT(1.0, precision: precision) / RT.sqrt(sx * sx + sy * sy)

        // Flags
        self.bStripes   = anypar.colorParameters.stripes > 0
        self.bSteps     = anypar.colorParameters.steps > 0
        self.bOrbits    = anypar.colorParameters.colorizeInside == .orbits
        self.bDist      = bStripes || bSteps || anypar.colorParameters.colorizeMode == .distance
        self.bShading   = bStripes || bSteps || anypar.colorParameters.colorizeOutside.isAny(of: [.simple3d, .blinnPhong])
        self.bFilaments = anypar.colorParameters.colorizeOutside == .filaments
        
        // Lightning
        self.lightning = Lightning(anypar.lightParameters)
        
        // Potential lookup table
        var pot: Double = 1.0
        self.potential = Array(repeating: 0.0, count: anypar.limits.iterations+1)
        for i in 0..<anypar.limits.iterations+1 {
            potential[i] = pot
            pot *= 0.5
        }
    }
    
}
