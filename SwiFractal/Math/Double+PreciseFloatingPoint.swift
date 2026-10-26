//
//  Double+PreciseFloatingPoint.swift
//  SwiFractal
//
//  Created by Dirk Braner on 25.10.26.
//

import Foundation
import SwiftMPx


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
    
    /// Initialize with literal Int value
    public init(integerLiteral value: Int) {
        self.init(value, precision: 53)
    }
    
    /// Convert to Double
    @inline(__always)
    public func toDouble() -> Double {
        return self
    }
    
    /// Convert to MPFloat
    @inline(__always)
    public func toMPFloat(precision: Int) -> MPFloat {
        return MPFloat(self, precision: precision)
    }
    
    /// Convert Double to String
    @inline(__always)
    public func toString() -> String {
        return String(format: "%g", self)
    }
    
    /// Rreturn absolute value
    @inline(__always)
    public static func abs(_ value: Double) -> Double {
        Swift.abs(value)
    }
    
    /// Minimum of two values
    @inline(__always)
    public static func min(_ lhs: Double, _ rhs: Double) -> Double {
        Swift.min(lhs, rhs)
    }
    
    /// Maximum of two values
    @inline(__always)
    public static func max(_ lhs: Double, _ rhs: Double) -> Double {
        Swift.max(lhs, rhs)
    }
    
    /// Floating point modulo division
    @inline(__always)
    public static func fmod(_ lhs: Double, _ rhs: Double) -> Double {
        return lhs.truncatingRemainder(dividingBy: rhs)
    }

    /// Check if absolute difference between two values is less or equal a tolerance value
    /// - Parameters:
    ///   - other: 2nd value
    ///   - tolerance: Tolerance. Default = 0: Identical with ==
    /// - Returns: true if values are almost equal
    @inline(__always)
    public func almostEqual(to other: Double, tolerance: Double) -> Bool {
        Swift.abs(self - other) < tolerance
    }
    
}
