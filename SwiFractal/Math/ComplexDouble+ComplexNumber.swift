//
//  ExtComplex.swift
//  SwiFractal
//
//  Created by Dirk Braner on 26.03.26.
//

import Foundation
import Numerics
import SwiftMPx


/// Shortcut for Complex type for Double values
public typealias Cplx = Complex<Double>


//
// Make Complex<Double> conform to ComplexNumber protocol
//
extension Complex<Double>: ComplexNumber, @retroactive LosslessStringConvertible {

    typealias RT = Double
    
    var precision: Int {
        return Swift.max(real.precision, imaginary.precision)
    }
    
    private func parseComplexNumber(_ input: String) -> (real: Double, imag: Double)? {
        guard !input.isEmpty else {
            return (0, 0)
        }
        let iPattern = /^(?<iSign>[+-])?i$/
        if let iMatch = input.wholeMatch(of: iPattern) {
            if let iSign = iMatch.output.iSign {
                return (0, iSign == "-" ? -1 : 1)
            }
            else {
                return (0, 1)
            }
        }
        
        // Regex-Muster mit benannten Gruppen für Realteil, Vorzeichen und Imaginärteil
        let pattern = /^(?<real>[+-]?\d+(?:\.\d+)?)(?<sign>[+-])?(?<imag>\d+(?:\.\d+)?)?i?$/
        
        // Prüfen, ob der gesamte String dem Muster entspricht
        guard let match = input.wholeMatch(of: pattern) else {
            return nil
        }
        
        // Realteil in Double umwandeln
        guard let real = Double(match.output.real) else {
            return nil
        }
        
        // Imaginärteil berechnen
        var imag: Double = 0.0
        if let sign = match.output.sign {
            let multiplier: Double = (sign == "-") ? -1.0 : 1.0
            if let imagString = match.output.imag {
                guard let imagValue = Double(imagString) else { return nil }
                imag = multiplier * imagValue
            } else {
                // Fall wie "3+i" oder "3-i" (ohne Ziffer vor dem i)
                imag = multiplier * 1.0
            }
        }
        
        return (real, imag)
    }
    
    /// Init with precision specifier
    public init(_ real: Double, _ imaginary: Double, precision: Int = 53) {
        self.init(real, imaginary)
    }
    
    /// Init with numeric strings
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
    
    
    /// Return square of complex number
    var squared: Cplx {
        .init(real * real - imaginary * imaginary, 2.0 * real * imaginary)
    }
    
    /// Return atan2(imaginary, real)
    var arg: Double {
        return atan2(imaginary, real)
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
    
    static func zero(precision: Int = 53) -> Complex<Double> {
        .init(0, 0)
    }
    
    func toMPComplex(precision: Int) -> MPComplex {
        return MPComplex(MPFloat(real, precision: precision), MPFloat(imaginary, precision: precision))
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
    
    /// Test if `(self - other).lengthSquared < tolerance`
    /// - Parameters:
    ///   - other: Other value
    ///   - tolerance: Tolerance
    /// - Returns: true if values are almost equal
    func almostEqual(to other: Cplx, tolerance: Double) -> Bool {
        let diff = self - other
        return diff.lengthSquared < tolerance
    }
    
}

extension String {
    
    /// Convert Cplx to String
    init (_ c: Cplx) {
        self = c.description
    }
    
}

