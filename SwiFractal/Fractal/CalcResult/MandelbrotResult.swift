//
//  MandelbrotResult.swift
//  SwiFractal
//
//  Created by Dirk Braner on 05.05.26.
//

import Foundation
import Metal64


protocol Bitmaskable : CaseIterable {
    var allNames: [String] { get }
    var highBit: Int { get }
    var allBits: Int { get }
}

extension Bitmaskable {
    
    var allNames: [String] { Self.allCases.map { String(describing: $0) } }
    var allBits: Int { (1 << (Self.allCases.count)) - 1 }
    var highBit: Int { Self.allCases.count - 1 }
    
}

///
/// Mandelbrot result flags
///
struct MandelbrotResultFlags: OptionSet, Bitmaskable, Sendable {

    let rawValue: Int

    static let defaultColor  = MandelbrotResultFlags(rawValue: 1)
    static let maxIterations = MandelbrotResultFlags(rawValue: 2)
    static let bailout       = MandelbrotResultFlags(rawValue: 4)
    static let inside        = MandelbrotResultFlags(rawValue: 8)
    static let error         = MandelbrotResultFlags(rawValue: 16)

    static let allCases: [MandelbrotResultFlags] = [.defaultColor, .maxIterations, .bailout, .inside, .error]

}


///
/// Mandelbrot calculation result
///
struct MandelbrotResult : CalculationResult {

    // Result values
    var smoothIter: Double = 0.0        // Smooth iteration counter
    var nZ: Double = 0.0
    var normalReal: Double = 0.0
    var normalImag: Double = 0.0
    var distance: Double = 0.0          // Distance to Mandelbrot set
    var potential: Double = 0.0         // Potential
    var stripeAvg: Double = 0.0         // Stripe average
    var filament: Double = 0.0          // Filament strength
    
    var flags: MandelbrotResultFlags = .defaultColor
    
    /// Convert MandelbrotResult to MandelbrotResultMtl
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

    /// Return smoothIter as histogram value
    var histValue: Double { smoothIter }
    
    /// Return true, if result contains valid histogram value (flags == .bailout)
    var hasValidHistValue: Bool { flags == .bailout }
    
    static let zero: MandelbrotResult = MandelbrotResult()
    static let defaultValue: MandelbrotResult = MandelbrotResult()
    
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
    
}


