//
//  MandelbrotResult.swift
//  SwiFractal
//
//  Created by Dirk Braner on 05.05.26.
//

import Foundation

/*
enum EnumMandelbrotResultFlags: Int, CaseIterable {
    case defaultColor
    case maxIterations
    case bailout
    case inside
    case error
}
typealias MandelbrotResultFlags = BitSet<EnumMandelbrotResultFlags>
*/


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

struct MandelbrotResultFlags: OptionSet, Bitmaskable, Sendable {

    let rawValue: Int

    static let defaultColor  = MandelbrotResultFlags(rawValue: 1)
    static let maxIterations = MandelbrotResultFlags(rawValue: 2)
    static let bailout       = MandelbrotResultFlags(rawValue: 4)
    static let inside        = MandelbrotResultFlags(rawValue: 8)
    static let error         = MandelbrotResultFlags(rawValue: 16)

    static let allCases: [MandelbrotResultFlags] = [.defaultColor, .maxIterations, .bailout, .inside, .error]

}


//
// Mandelbrot calculation result
//
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

    /// Return smoothIter as histogram value
    var histValue: Double { smoothIter }
    
    /// Return true, if result contains valid histogram value (flags == .bailout)
    var hasValidHistValue: Bool { flags == .bailout }
    
    static let zero: MandelbrotResult = MandelbrotResult()
    static let defaultValue: MandelbrotResult = MandelbrotResult()

}



