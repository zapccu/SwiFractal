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
/// Some constants. Prevent memory allocation in iteration loop for high precision data types
///
nonisolated struct DynamicConstantValues<PT: FractalData> {
    let ctZero: PT.CT
    let ctOne: PT.CT
    let ctTwo: PT.CT
    let rtZero: PT.RT
    let rtOne: PT.RT
    let rtTwo: PT.RT
}

///
/// Dynamic fractal calculation parameters.
/// Contains fractal parameters needed for calculation and color mapping.
///
nonisolated struct DynamicParameters<PT: FractalData>: MetalEncodable {

    typealias RT = PT.RT
    typealias CT = PT.CT
    
    /// Constant values
    let constantValues: DynamicConstantValues<PT>
    
    /// Snapshot of application settings
    let settings: SettingsSnapshot
    
    /// Initial value mapping based on fractal type
    let initial: InitialValueMapping<CT>
    
    /// Update calculation progress
    let progress: CalculationProgress
        
    /// Mantissa precision bits
    let precision: Int

    /// Image dimensions without oversampling
    let resolution: CGSize
    
    /// Fractal dimensions
    let dimensions: FractalDimensions<RT>
    
    /// Image width considering oversampling
    let osImageWidth: Int
    
    /// Image height considering oversampling
    let osImageHeight: Int
    
    /// Image size considering oversampling
    let osSize: ISize
    
    /// Limits with precalculated values
    let limits: FractalDynamicLimits
        
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
    let colorizeInside: ColorizeInside
    
    /// Lightning
    let lightning: Lightning         // Lightning depends on LightningParameters

    var extendedInfo: ResultContains = []
    
    /// Initialize dynamic calculation parameters
    /// - Parameters:
    ///   - anypar: Static fractal parameters
    ///   - resolution: Image resolution without oversampling
    ///   - progress: Calculation progress
    ///   - settings: Snapshot of application settings
    init(anypar: PT, resolution: CGSize, progress: CalculationProgress, settings: SettingsSnapshot) {
        self.progress = progress
        self.settings = settings
        
        let precision = anypar.dimensions.precision.bits
        self.constantValues = DynamicConstantValues(
            ctZero: CT(0.0, 0.0, precision: precision),
            ctOne: CT(1.0, 0.0, precision: precision),
            ctTwo: CT(2.0, 0.0, precision: precision),
            rtZero: RT(0.0, precision: precision),
            rtOne: RT(1.0, precision: precision),
            rtTwo: RT(2.0, precision: precision)
        )
        self.precision = precision
        
        // Mapping of initial iteration values
        self.initial = anypar.initialMapping
        
        // Resolutions
        self.resolution    = resolution
        self.osImageWidth  = Int(resolution.width) * anypar.dimensions.oversampling
        self.osImageHeight = Int(resolution.height) * anypar.dimensions.oversampling
        self.osSize        = ISize(width: osImageWidth, height: osImageHeight)

        // Dimensions
        self.dimensions = anypar.dimensions
        let sx = anypar.dimensions.sizeX
        let sy = anypar.dimensions.sizeY

        // Distance threshold for filaments and series approximation
        let (dx, dy) = anypar.dimensions.pixelDistance(resolution: resolution)
        self.minPixelDistance = min(dx, dy)
        self.logPixel = RT.log(minPixelDistance).toDouble()
        self.invDistThreshold = RT(1.0, precision: precision) / min(dx, dy) * 0.5
        self.logMinSize = RT.log(min(RT(0.5, precision: precision), min(sx, sy))).toDouble()

        // Limits
        self.limits = FractalDynamicLimits(limits: anypar.limits, precision: anypar.dimensions.precision.bits)
        
        // Orbits / colorize interior of Mandelbrot set
        self.colorizeInside = anypar.colorParameters.colorizeInside

        // Stripes
        self.bStripes = anypar.colorParameters.colorizeMode == .stripes && anypar.colorParameters.stripes > 0
        self.stripes = anypar.colorParameters.stripes
        self.stripeSig = anypar.colorParameters.stripeSig
        
        // Lightning
        self.lightning = Lightning(anypar.lightParameters)
        
        if self.bStripes { self.extendedInfo |= .stripes }
        if anypar.colorParameters.colorizeInside.isNone(of: [.defaultColor, .fastOrbits]) { self.extendedInfo |= .orbits }
    }
    
    /// Create Metal compute parameters from DynamicParameters
    /// - Returns: Metal compute parameters.
    func toMetal() -> MetalComputeParameters {
        MetalComputeParameters(
            iterations: Int32(limits.iterations),
            bStripes: bStripes ? 1 : 0,
            colorizeInside: Int32(colorizeInside.rawValue),
            bailout: Float(limits.bailout),
            logBailout: Float2(limits.logBailout),
            // div_2_logBailout: Float2(limits.div_2_logBailout),
            stripes: Float2(stripes),
            stripeSig: Float2(stripeSig),
            logPixel: Float2(logPixel),
            invDistThreshold: Float2(invDistThreshold.asDouble)
        )
    }
    
}
