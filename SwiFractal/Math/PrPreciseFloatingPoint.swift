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


//
// PreciseFloatingPoint protocol
//
protocol PreciseFloatingPoint: BasicCalculations & RealFunctions & Codable & Sendable & ExpressibleByFloatLiteral, Comparable {
    
    // Associated complex type
    associatedtype CT: ComplexNumber where CT.RT == Self
    
    // Precision tag for JSON export/import
    static var precisionTag: PrecisionTag { get }
    
    // Number of bits
    var precision: Int { get }
    
    // Check for infinity
    var isInfinite: Bool { get }
    
    // Check for not a number
    var isNaN: Bool { get }
    
    // Zero
    static var zero: Self { get }

    // Not a number
    static var nan: Self { get }
    
    // Convert to MPFloat
    var asMPFloat: MPFloat { get }
    
    // Convert to Double
    var asDouble: Double { get }
    
    // Initializers
    init(_ value: Int, precision: Int)
    init(_ value: Double, precision: Int)
    init(_ value: MPFloat, precision: Int)
    init(_ value: String, precision: Int)

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
    
    // Floating point modulo division
    static func fmod(_ lhs: Self, _ rhs: Self) -> Self
    
}

//
// Initialize value by literal
//
extension PreciseFloatingPoint {
    
    /// Initialize with literal Double value
    public init(floatLiteral value: Double) {
        self.init(value, precision: 64)
    }
    
    /// Initialize with literal Int value
    public init(integerLiteral value: Int) {
        self.init(value, precision: 64)
    }
    
    /// Cubic interpolation
    public static func interpolateCubic(edge0: Self, edge1: Self, x: Self) -> Self {
        // map x into [0, 1]
        // If x < edge0: t = 0; if x > edge1: t = 1
        let t = Self.min(Self.max((x - edge0) / (edge1 - edge0), 0.0), 1.0)
        
        // Cubic Hermite interpolation
        return t * t * (3.0 - 2.0 * t)
    }
    
    /// Linear interpolation
    public static func lerp(a: Self, b: Self, t: Self) -> Self {
        return a + (b - a) * t
    }
    
    /// Exact linear interpolation
    public static func lerpExact(a: Self, b: Self, t: Self) -> Self {
        return (1.0 - t) * a + t * b
    }
    
}

//
// Linear spacing
//
extension PreciseFloatingPoint {
    
    /// Create an array with linear distributed foating point values
    /// - Parameters:
    ///   - start: First value of array
    ///   - end: Last value of array
    ///   - n: Number of values in array
    /// - Returns: Array of size n
    public static func linspace(_ start: Self, _ end: Self, _ n: Int) -> [Self] {
        guard n > 0 else { return [] }
        let step = (end - start) / Self(n - 1, precision: start.precision)
        var a = Array(0..<n).map { Self($0, precision: start.precision) * step + start }
        
        // Prevent rounding errors for last array element
        if n > 1 { a[n-1] = end }
        
        return a
    }
    
}

//
// Make Double conform to protocol PreciseFloatingPoint
//
extension Double : PreciseFloatingPoint {
    
    typealias CT = Cplx    // Cplx = Complex<Double>
    
    static var precisionTag: PrecisionTag { .double }
    
    var precision: Int { 53 }       // Mantissa of Double has 53-bit precision (IEEE 754)
    
    /// Convert Double to MPFloat using MPFloat.defaultPrecision
    public var asMPFloat: MPFloat { MPFloat(self) }
    
    /// Convert Double to Double
    public var asDouble: Double { self }
    
    // Initialize with Int value
    public init(_ value: Int, precision: Int = 53) {
        self = Double(value)
    }
    
    // Initialize with Double value
    public init(_ value: Double, precision: Int = 53) {
        self = value // Precision ignored, 53 bit
    }
    
    // Initialize with MPFloat value
    public init(_ value: MPFloat, precision: Int = 53) {
        self = value.toDouble()
    }
    
    // Initialize with numeric String value
    public init(_ value: String, precision: Int = 53) {
        self = Double(value) ?? 0
    }
    
    /// Convert to Double
    public func toDouble() -> Double {
        return self
    }
    
    /// Convert to MPFloat
    public func toMPFloat(precision: Int) -> MPFloat {
        return MPFloat(self, precision: precision)
    }
    
    /// Convert Double to String
    public func toString() -> String {
        return String(format: "%g", self)
    }
    
    /// Rreturn absolute value
    public static func abs(_ value: Double) -> Double {
        Swift.abs(value)
    }
    
    /// Minimum of two values
    public static func min(_ lhs: Double, _ rhs: Double) -> Double {
        Swift.min(lhs, rhs)
    }
    
    /// Maximum of two values
    public static func max(_ lhs: Double, _ rhs: Double) -> Double {
        Swift.max(lhs, rhs)
    }
    
    /// Floating point modulo division
    public static func fmod(_ lhs: Self, _ rhs: Self) -> Self {
        return lhs.truncatingRemainder(dividingBy: rhs)
    }
    
}

//
// Make MPFloat conform to PreciseFloatingPoint
//
extension MPFloat: @retroactive RealFunctions {}
extension MPFloat: @retroactive ElementaryFunctions {}
extension MPFloat: @retroactive AdditiveArithmetic {}

extension MPFloat : PreciseFloatingPoint {
    
    typealias CT = MPComplex

    public static var precisionTag: PrecisionTag { .mpfloat }
    
    public static var zero: MPFloat { MPFloat(0) }
    
    /// Convert MPFloat to MPFloat
    public var asMPFloat: MPFloat { self }
    
    /// Convert MPFloat to Double
    public var asDouble: Double { Double(self.toDouble()) }
    
    /// Convert to MPFloat
    public func toMPFloat(precision: Int) -> MPFloat {
        MPFloat(self, precision: precision)
    }
    
}

