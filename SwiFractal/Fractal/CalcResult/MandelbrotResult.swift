//
//  MandelbrotResult.swift
//  SwiFractal
//
//  Created by Dirk Braner on 05.05.26.
//

import Foundation
import Metal64
import MetalCompute


protocol Bitmaskable : CaseIterable {
    var allNames: [String] { get }
    var highBit: Int { get }
    var allBits: Int { get }
}

extension Bitmaskable {
    
    var allNames: [String] { Self.allCases.map { String(describing: $0) } }
    var allBits: Int { (1 << (Self.allCases.count)) - 1 }
    var highBit: Int { Self.allCases.count - 1 }
    
    var name: String { String(describing: self) }
    
}

///
/// Mandelbrot result flags
/// Any change on these flags must be synchronized with flags defined in Metal/mandelbrot.h
///
struct MandelbrotResultFlags: OptionSet, Bitmaskable, Sendable {

    let rawValue: Int

    /// Not yet calculated
    static let calculate = MandelbrotResultFlags(rawValue: 1)
    
    /// Assign default color
    static let defaultColor = MandelbrotResultFlags(rawValue: 2)
    
    /// Maximum number of iterations reached
    static let maxIterations = MandelbrotResultFlags(rawValue: 4)
    
    /// Bailout exceeded
    static let bailout = MandelbrotResultFlags(rawValue: 8)
    
    /// Inside Mandelbrot set
    static let inside = MandelbrotResultFlags(rawValue: 16)
    
    /// Error during calculation
    static let error = MandelbrotResultFlags(rawValue: 32)

    /// Bitmask for all cases except .calculate
    static let allCases: [MandelbrotResultFlags] = [.defaultColor, .maxIterations, .bailout, .inside, .error]

}


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
    var flags: MandelbrotResultFlags = .calculate
    
    /// Return smoothIter as histogram value
    var histValue: Double { smoothIter }
    
    /// Return true, if result contains valid histogram value (flags == .bailout)
    var hasValidHistValue: Bool { flags == .bailout }
    
    /// Zero result. flags = .defaultColor
    static let zero: MandelbrotResult = MandelbrotResult(flags: .defaultColor)
    
    /// Initial result. flags = .calculate
    static let initialValue: MandelbrotResult = MandelbrotResult(flags: .calculate)
    
    /// Default result. flags = .defaultColor
    static let defaultValue: MandelbrotResult = MandelbrotResult(flags: .defaultColor)
    
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


