//
//  PrPreciseFloatingPoint.swift
//  SwiFractal
//
//  Created by Dirk Braner on 08.05.26.
//

import Foundation
import Numerics
import SwiftMPx


public enum PrecisionTag: String, Codable {
    case double
    case mpfloat
}


///
/// PreciseFloatingPoint protocol
///
protocol PreciseFloatingPoint: BasicCalculations & RealFunctions & Codable & Sendable & ExpressibleByFloatLiteral, Comparable {
    
    // Associated complex type
    associatedtype CT: ComplexNumber where CT.RT == Self
    
    /// Precision tag for JSON export/import
    static var precisionTag: PrecisionTag { get }
    
    // Number of bits
    var precision: Int { get }
    
    // Check for infinity
    var isInfinite: Bool { get }
    
    // Check for not a number
    var isNaN: Bool { get }

    // Not a number
    static var nan: Self { get }
    
    /// Return the sign of a value
    var sign: FloatingPointSign { get }
    
    // Convert to MPFloat
    var asMPFloat: MPFloat { get }
    
    // Convert to Double
    var asDouble: Double { get }
    
    // Initializers
    init(_ value: Int, precision: Int)
    init(_ value: Double, precision: Int)
    init(_ value: MPFloat, precision: Int)
    init(_ value: String, precision: Int)
    init(floatLiteral value: Double)
    init(integerLiteral value: Int)

    // Convert to Double
    func toDouble() -> Double
    
    // Convert to MPFloat with specified precision
    func toMPFloat(precision: Int) -> MPFloat
    
    // Convert to String
    func toString() -> String
        
    // Unary minus
    static prefix func - (value: Self) -> Self
    
    // Absolute value
    static func abs(_ value: Self) -> Self
    
    // Minimum of two values
    static func min(_ lhs: Self, _ rhs: Self) -> Self
    
    // Maximum of two values
    static func max(_ lhs: Self, _ rhs: Self) -> Self
    
    /// Sign of value
    
    // Floating point modulo division
    static func fmod(_ lhs: Self, _ rhs: Self) -> Self
    
    // Power with int exponent
    static func pow(_ lhs: Self, _ exponent: Int) -> Self

    // Linear interpolation
    static func lerp(a: Self, b: Self, t: Self) -> Self
    
    // Exact linear interpolation
    static func lerpExact(a: Self, b: Self, t: Self) -> Self
    
    // Cubic interpolation
    static func interpolateCubic(edge0: Self, edge1: Self, x: Self) -> Self
    
    // Linear spacing
    static func linspace(_ start: Self, _ end: Self, _ n: Int) -> [Self]
    
    func almostEqual(to other: Self, tolerance: Self) -> Bool
}




