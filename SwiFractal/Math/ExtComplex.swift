//
//  ExtComplex.swift
//  SwiFractal
//
//  Created by Dirk Braner on 26.03.26.
//

import Foundation
import Numerics
import SwiftMPx

// ------------------------------------
//  Complex<Double>
// ------------------------------------

/// Shortcut for Complex type for Double values
public typealias Cplx = Complex<Double>


extension Complex<Double>: ComplexNumber, @retroactive LosslessStringConvertible {
    
    typealias PrecisionType = Double
    
    public init(_ real: Double, _ imaginary: Double, precision: Int = 64) {
        self.init(real, imaginary)
    }
    
    public init?(_ real: String, _ imaginary: String) {
        guard let real = Double(real), let imaginary = Double(imaginary) else { return nil }
        self.init(real, imaginary)
    }
    
    /// Convert String to Complex
    /// String format: FloatingPoint[+FloatingPoint["i"]]
    public init?(_ str: String) {
        var s = str
        
        if s.last == "i" { s.removeLast() }
        let parts = s.split(separator: "+")
        guard parts.count == 1 || parts.count == 2 else { return nil }
        
        if parts.count == 1, let r = Double(parts[0]) {
            self.init(r, 0.0)
        }
        else if parts.count == 2, let r = Double(parts[0]), let i = Double(parts[1]) {
            self.init(r, i)
        }
        else {
            return nil
        }
    }
    
    /// Return complex value as String
    var description: String {
        return "\(real)+\(imaginary)i"
    }
    
    /// Return real * real + imaginary * imaginary
    var norm: Double {
        return lengthSquared
    }
    
    /// Return atan2(imaginary, real)
    var arg: Double {
        return atan2(imaginary, real)
    }
    
    /// Return sqrt(real * real + imaginary * imaginary)
    var abs: Double {
        return length
    }
    
    /// Return minimum of real and imaginary part
    var min: Double {
        return Swift.min(real, imaginary)
    }
    
    /// Return maximum of real and imaginary part
    var max: Double {
        return Swift.min(real, imaginary)
    }
    
    /// Return epsilon
    var ulp: Double {
        return Swift.max(real.ulp, imaginary.ulp)
    }
    
    /// Convert to Cplx
    func toCplx() -> Cplx {
        return self
    }
    
    /// Compare Cplx
    static func != (lhs: Cplx, rhs: Cplx) -> Bool {
        return lhs.real != rhs.real || lhs.imaginary != rhs.imaginary
    }
    
    /// Multiply Cplx with Double
    static func * (lhs: Cplx, rhs: Double) -> Cplx {
        return lhs * Cplx(rhs)
    }

    /// Multiply Double with Cplx
    static func * (lhs: Double, rhs: Cplx) -> Cplx {
        return Cplx(lhs) * rhs
    }

    /// Divide Cplx by Double
    static func / (lhs: Cplx, rhs: Double) -> Cplx {
        return lhs / Cplx(rhs)
    }

    /// Divide Double by Cplx
    static func / (lhs: Double, rhs: Cplx) -> Cplx {
        return Cplx(lhs) / rhs
    }

    /// Add Cplx to Double
    static func + (lhs: Cplx, rhs: Double) -> Cplx {
        return lhs + Cplx(rhs)
    }

    /// Add Double to Cplx
    static func + (lhs: Double, rhs: Cplx) -> Cplx {
        return Cplx(lhs) + rhs
    }

    /// Subtract Double from Cplx
    static func - (lhs: Cplx, rhs: Double) -> Cplx {
        return lhs - Cplx(rhs)
    }
    
    /// Subtract Cplx from Double
    static func - (lhs: Double, rhs: Cplx) -> Cplx {
        return Cplx(lhs) - rhs
    }
}

extension String {
    /// Convert Cplx to String
    init (_ c: Cplx) {
        self = c.description
    }
}

