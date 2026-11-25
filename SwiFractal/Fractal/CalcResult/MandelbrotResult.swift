//
//  MandelbrotResult.swift
//  SwiFractal
//
//  Created by Dirk Braner on 05.05.26.
//

import Foundation
import Metal64
import MetalCompute


///
/// Result flags
///
enum EnumResultFlags : Int, NamedBit {
    case calculate
    case defaultColor
    case maxIterations
    case bailout
    case inside
    case error
}
typealias MandelbrotResultFlags = BitSet<EnumResultFlags>


///
/// Mandelbrot calculation result
///
struct MandelbrotResult : CalculationResult, MetalDecodable {
    
    /// Smooth iteration counter
    var smoothIter: Double = 0.0
    
    /// Last value of Z.lengthSquared
    var nZ: Double = 0.0
    
    /// Real part of Z/D
    var normalReal: Double = 0.0
    
    /// Imaginary part of Z/D
    var normalImag: Double = 0.0
    
    /// Distance to Mandelbrot set.
    /// Contains log(Distance) for points outside of Mandelbrot set.
    /// Contains orbit period for points inside of Mandelbrot set.
    var distance: Double = 0.0
    
    /// Stripe average
    var stripeAvg: Double = 0.0
    
    /// Filament strength
    var filament: Double = 0.0
    
    /// Flags: .calculate, .defaultColor, .maxIterations, .bailout, .inside, .error
    var flags: MandelbrotResultFlags = [.calculate]
    
    /// Return smoothIter as histogram value
    var histValue: Double { smoothIter }
    
    /// Return true, if result contains valid histogram value (flags == .bailout)
    var hasValidHistValue: Bool { flags.isSet(.bailout) }
    
    /// Zero result. flags = .defaultColor.
    /// Not used but kept for protocol conformance.
    static let zero: MandelbrotResult = MandelbrotResult(flags: [.defaultColor])
    
    /// Initial result. flags = .calculate
    static let initialValue: MandelbrotResult = MandelbrotResult(flags: [.calculate])
    
    /// Default result. flags = .defaultColor
    static let defaultValue: MandelbrotResult = MandelbrotResult(flags: [.defaultColor])
    
}

extension MandelbrotResult {
    
    /// Convert MandelbrotResultMtl to MandelbrotResult
    init(fromMetal m: MandelbrotResultMtl) {
        self.init(
            smoothIter: Double(fromMetal: m.smoothIter),
            nZ: Double(fromMetal: m.nZ),
            normalReal: Double(fromMetal: m.normalReal),
            normalImag: Double(fromMetal: m.normalImag),
            distance: Double(fromMetal: m.distance),
            stripeAvg: Double(fromMetal: m.stripeAvg),
            filament: Double(fromMetal: m.filament),
            flags: MandelbrotResultFlags(rawValue: Int(m.flags))
        )
    }
    
}

///
/// Mandelbrot Result returned by Metal calculation function.
/// Must be converted into MandelbrotResult
///
struct MandelbrotResultMtl {
    
    var smoothIter: Float2
    var nZ: Float2
    var normalReal: Float2
    var normalImag: Float2
    var distance: Float2
    var stripeAvg: Float2
    var filament: Float2
    var flags: Int32

}


