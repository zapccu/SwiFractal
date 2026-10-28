//
//  PrComplexNumber.swift
//  SwiFractal
//
//  Created by Dirk Braner on 07.05.26.
//

import Numerics
import SwiftMPx


///
/// Protocol for complex numbers
///
protocol ComplexNumber : Sendable {
    
    associatedtype RT: PreciseFloatingPoint
    associatedtype Scratch
    
    /// Precision. Size of mantissa in bits
    var precision: Int { get }
    
    /// Real part
    var real: RT { get }
    
    /// Imaginary part
    var imaginary: RT { get }
    
    /// Return squared Euclidean norm: real * real + imaginary * imaginary
    var lengthSquared: RT { get }
    
    /// Return Euclidean norm: sqrt(real * real + imaginary * imaginary)
    var length: RT { get }
    
    /// Return square
    var squared: Self { get }
    
    /// Return angle betweend imaginary and real part
    var arg: RT { get }
    
    /// Return minimum of real and imaginary part
    var min: RT { get }
    
    /// Return maximum of real and imaginary part
    var max: RT { get }
    
    /// Return complex value as String
    var description: String { get }
        
    /// Constructor. Precision is max(real.precision, imaginary.precision)
    init(_ real: RT, _ imaginary: RT)
    
    /// Constructor with precision support
    init(_ real: RT, _ imaginary: RT, precision: Int)
    
    /// Return zero
    static func zero(precision: Int) -> Self
    
    /// Convert to Double precision complex value
    func toCplx() -> Cplx
    
    /// Convert to arbitrary precision complex value
    func toMPComplex(precision: Int) -> MPComplex
    
    // Addition
    static func + (lhs: Self, rhs: Self) -> Self
    static func + (lhs: Self, rhs: RT) -> Self
    static func + (lhs: RT, rhs: Self) -> Self
    
    // Subtraction
    static func - (lhs: Self, rhs: Self) -> Self
    static func - (lhs: Self, rhs: RT) -> Self
    static func - (lhs: RT, rhs: Self) -> Self
    
    // Multiplication
    static func * (lhs: Self, rhs: Self) -> Self
    static func * (lhs: Self, rhs: RT) -> Self
    static func * (lhs: RT, rhs: Self) -> Self
    
    // Division
    static func / (lhs: Self, rhs: Self) -> Self
    static func / (lhs: Self, rhs: RT) -> Self
    static func / (lhs: RT, rhs: Self) -> Self
    
    // Comparison operators and functions
    static func == (lhs: Self, rhs: Self) -> Bool
    static func != (lhs: Self, rhs: Self) -> Bool
    func almostEqual(to other: Self, tolerance: RT) -> Bool
    
    //
    // Built in formulas
    //
    
    /// Create a scratch value. Call once before the iteration loop and reuse it.
    /// - Parameter precision: Precision in bits (ignored by fixed precision types)
    static func makeScratch(precision: Int) -> Scratch
    
    /// D = 2·D·Z + 1, in place. Must be called with Z of the current iteration (before squareAdd)
    mutating func derivativeStep(z: Self, isJulia: Bool, scratch: inout Scratch)
    
    /// Calculate z = z² + c, in place.
    mutating func squareAdd(_ c: Self, scratch: inout Scratch)
    mutating func squareAdd(_ c: Self)
    
    /// Calculate z = z², in place.
    mutating func square(scratch: inout Scratch)
    
}







