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
import MetalCompute


///
/// Dynamic fractal calculation parameters
///
/// Contains fractal parameters needed for calculation and color mapping.
///
nonisolated struct DynamicParameters<PT: FractalData>: MetalEncodable {

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
    let logDiag: RT                     // log(1 / abs(size))
    
    /// Minimum pixel distance\
    /// `min(dx, dy)`
    let minPixelDistance: RT
    
    /// Logarithm of min pixel distance\
    /// `RT.log(minPixelDistance).toDouble()`
    let logPixel: Double
    
    /// Inverse threshold of min pixel distance for filament calculation\
    /// `RT(1.0, precision: precision) / min(dx, dy) * 0.5`
    let invDistThreshold: RT            // 1 / pixelDistance * 0.5
    
    /// Logarithm of minimum of 0.5 and maximum complex size for interior distance coloring\
    /// `log(min(RT(0.5, precision: precision), min(sx, sy))).toDouble()`
    let logMinSize: Double
    
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
    
    /// Thresholds for orbit detection
    let t1: Double
    let t2: Double
    let t3: Double
    
    var extendedInfo: ResultContains = []
    
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
        self.resolution    = resolution
        self.imageWidth    = Int(resolution.width)
        self.imageHeight   = Int(resolution.height)
        self.osImageWidth  = Int(resolution.width) * anypar.dimensions.oversampling
        self.osImageHeight = Int(resolution.height) * anypar.dimensions.oversampling
        self.osSize        = ISize(width: osImageWidth, height: osImageHeight)
        
        // Dimensions
        self.dimensions = anypar.dimensions
        let sx = anypar.dimensions.sizeX
        let sy = anypar.dimensions.sizeY
        self.logDiag = RT.log(RT(1.0, precision: precision) / RT.sqrt(sx * sx + sy * sy))

        // Distance threshold for filaments and series approximation
        let (dx, dy) = anypar.dimensions.pixelDistance(resolution: resolution)
        self.minPixelDistance = min(dx, dy)
        self.logPixel = RT.log(minPixelDistance).toDouble()
        self.invDistThreshold = RT(1.0, precision: precision) / min(dx, dy) * 0.5
        self.logMinSize = RT.log(min(RT(0.5, precision: precision), min(sx, sy))).toDouble()

        // Limits
        self.limits = FractalDynamicLimits(anypar.limits)
        
        // Tolerances
        // P.logPixel = log(Pixelsize); calculate in Log space to prevent underflows
        let logEps = min(max(self.logPixel + log(8.0), log(anypar.limits.orbitDelta1)), log(3e-6))
        self.t1 = exp(2.0 * logEps)
        self.t2 = t1 * anypar.limits.orbitDeltaF
        self.t3 = anypar.limits.orbitDelta3
        
        // Orbits / colorize interior of Mandelbrot set
        self.colorizeInside = anypar.colorParameters.colorizeInside.element

        // Stripes
        self.bStripes = anypar.colorParameters.colorizeMode == .stripes && anypar.colorParameters.stripes > 0
        self.stripes = anypar.colorParameters.stripes
        self.stripeSig = anypar.colorParameters.stripeSig
        
        // Lightning
        self.lightning = Lightning(anypar.lightParameters)
        
        if self.bStripes { self.extendedInfo |= .stripes }
        if anypar.colorParameters.colorizeInside == .orbits { self.extendedInfo |= .orbits }
    }
    
    func toMetal() -> MetalComputeParameters {
        MetalComputeParameters(
            iterations: Int32(limits.iterations),
            bStripes: bStripes ? 1 : 0,
            bailout: Float(limits.bailout),
            logBailout: Float2(limits.logBailout),
            div_2_logBailout: Float2(limits.div_2_logBailout),
            stripes: Float2(stripes),
            stripeSig: Float2(stripeSig),
            logPixel: Float2(logPixel),
            invDistThreshold: Float2(invDistThreshold.asDouble)
        )
    }
    
}
