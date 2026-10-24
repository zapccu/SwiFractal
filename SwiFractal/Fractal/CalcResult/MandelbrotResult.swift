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
    
    /// Potential
    var potential: Double = 0.0
    
    /// Stripe average
    var stripeAvg: Double = 0.0
    
    /// Filament strength
    var filament: Double = 0.0
    
    /// Flags: .calculate, .defaultColor, .maxIterations, .bailout, .inside, .error
    var flags: MandelbrotResultFlags = .calculate
    
    /// Convert MandelbrotResult to MandelbrotResultMtl
    /*
    var mandelbrotResultMtl: MandelbrotResultMtl {
        MandelbrotResultMtl(
            smoothIter: Float2(smoothIter),
            nZ: Float2(nZ),
            normalReal: Float2(normalReal),
            normalImag: Float2(normalImag),
            distance: Float2(distance),
            potential: Float2(potential),
            stripeAvg: Float2(stripeAvg),
            filament: Float2(filament),
            flags: Int32(flags.rawValue)
        )
    }
     */

    /// Return smoothIter as histogram value
    var histValue: Double { smoothIter }
    
    /// Return true, if result contains valid histogram value (flags == .bailout)
    var hasValidHistValue: Bool { flags == .bailout }
    
    /// Zero result. flags = .calculate
    static let zero: MandelbrotResult = MandelbrotResult()
    
    /// Initial result. flags = .calculate
    static let initialValue: MandelbrotResult = MandelbrotResult()
    
    /// Default result. flags = .defaultColor
    static let defaultValue: MandelbrotResult = MandelbrotResult(flags: .defaultColor)
    
    init(smoothIter: Double = 0.0, nZ: Double = 0.0, normalReal: Double = 0.0, normalImag: Double = 0.0, distance: Double = 0.0, potential: Double = 0.0, stripeAvg: Double = 0.0, filament: Double = 0.0, flags: MandelbrotResultFlags = .defaultColor) {
        self.smoothIter = smoothIter
        self.nZ = nZ
        self.normalReal = normalReal
        self.normalImag = normalImag
        self.distance = distance
        self.potential = potential
        self.stripeAvg = stripeAvg
        self.filament = filament
        self.flags = flags
    }
    
    /// Convert MandelbrotResultMtl to MandelbrotResult
    init(fromMetal m: MandelbrotResultMtl) {
        self.init(
            smoothIter: Double(fromMetal: m.smoothIter),
            nZ: Double(fromMetal: m.nZ),
            normalReal: Double(fromMetal: m.normalReal),
            normalImag: Double(fromMetal: m.normalImag),
            distance: Double(fromMetal: m.distance),
            potential: Double(fromMetal: m.potential),
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
    var potential: Float2
    var stripeAvg: Float2
    var filament: Float2
    var flags: Int32
    
    /// Convert MandelbrotResultMtl to MandelbrotResult
    /*
    var mandelbrotResult: MandelbrotResult {
        MandelbrotResult(
            smoothIter: Double(smoothIter),
            nZ: Double(nZ),
            normalReal: Double(normalReal),
            normalImag: Double(normalImag),
            distance: Double(distance),
            potential: Double(potential),
            stripeAvg: Double(stripeAvg),
            filament: Double(filament),
            flags: MandelbrotResultFlags(rawValue: Int(flags))
        )
    }
     */
    
}


