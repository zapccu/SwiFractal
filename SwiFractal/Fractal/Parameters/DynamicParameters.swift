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


///
/// Dynamic fractal calculation parameters
///
/// Contains fractal parameters needed for calculation and color mapping.
///
nonisolated struct DynamicParameters<PT: FractalData> {

    typealias RT = PT.RT
    typealias CT = PT.CT
    
    //static var output: Bool = false
    
    let parameterType: PT.Type
    
    /// Snapshot of application settings
    let settings: SettingsSnapshot
    
    /// Initial value mapping based on fractal type
    let initial: InitialValueMapping<CT>
        
    /// Mantissa precision bits
    let precision: Int
    
    /// Use perturbation algorithm
    let bPerturbation: Bool
    
    /// Number of points to skip
    let skip: Int

    /// Image dimensions without oversampling
    let resolution: CGSize
    
    /// Fractal dimensions
    let dimensions: FractalDimensions<RT>
    
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
    
    /// Limits with precalculated values
    let limits: FractalDynamicLimits
        
    /// Distance normalization factor
    let diag: RT                     // 1 / abs(size)
    
    /// Minimum pixel distance
    let minPixelDistance: RT
    
    /// Threshold for filament calculation
    let distThreshold: RT            // pixelDistance * 0.5
    
    /// Calculate stripes
    let bStripes: Bool
    
    /// Stripe density
    let stripes: Int
    
    /// Stripe memory parameter
    let stripeSig: Double
    
    /// Calculate orbits
    let colorizeInside: EnumColorizeInside
    
    /// Lightning
    let lightning: Lightning         // Lightning depends on LightningParameters
    
    /// Array with potential values:\
    /// `potential[n] = 1/2^n, n=0..<iterations`
    var potential: [Double] = []
    
    /// Return Metal compute parameters
    var computeParameters: MetalComputeParameters {
        MetalComputeParameters(
            iterations: Int32(limits.iterations),
            bStripes: bStripes ? 1 : 0,
            bailout: Float(limits.bailout),
            logBailout: Float2(limits.logBailout),
            div_2_logBailout: Float2(limits.div_2_logBailout),
            stripes: Float2(stripes),
            stripeSig: Float2(stripeSig),
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
        self.parameterType = type(of: anypar)
        
        self.settings = settings
        
        self.precision = anypar.dimensions.precision.bits
        self.bPerturbation = settings.usePerturbation || anypar.dimensions.renderPrecision == .perturbation
        
        // Number of pixels to skip during calculation
        self.skip = 0
        
        // Mapping of initial iteration values
        self.initial = anypar.initialMapping
        
        // Resolutions
        self.resolution = resolution
        self.imageWidth  = Int(resolution.width)
        self.imageHeight = Int(resolution.height)
        self.osImageWidth = Int(resolution.width) * anypar.dimensions.oversampling
        self.osImageHeight = Int(resolution.height) * anypar.dimensions.oversampling
        self.osSize = ISize(width: osImageWidth, height: osImageHeight)
        
        // Dimensions
        self.dimensions = anypar.dimensions
        let sx = anypar.dimensions.sizeX
        let sy = anypar.dimensions.sizeY
        self.diag = RT(1.0, precision: precision) / RT.sqrt(sx * sx + sy * sy)

        // Distance threshold for filaments and series approximation
        let (dx, dy) = anypar.dimensions.pixelDistance(resolution: resolution)
        self.minPixelDistance = min(dx, dy)
        self.distThreshold = min(dx, dy) * 0.5

        // Limits
        self.limits = FractalDynamicLimits(anypar.limits)
        
        // Orbits / colorize interior of Mandelbrot set
        self.colorizeInside = anypar.colorParameters.colorizeInside.element

        // Stripes
        self.bStripes = anypar.colorParameters.stripes > 0
        self.stripes = anypar.colorParameters.stripes
        self.stripeSig = anypar.colorParameters.stripeSig
        
        // Lightning
        self.lightning = Lightning(anypar.lightParameters)
        
        // Build potential lookup table
        var pot: Double = 1.0
        self.potential = Array(repeating: 0.0, count: anypar.limits.iterations + 1)
        for i in 0...anypar.limits.iterations {
            potential[i] = pot
            pot *= 0.5
        }
    }
    
}
