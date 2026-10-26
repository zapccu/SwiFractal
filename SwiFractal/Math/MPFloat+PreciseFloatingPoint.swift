//
//  MPFloat+PreciseFloatingPoint.swift
//  SwiFractal
//
//  Created by Dirk Braner on 25.10.26.
//

import Foundation
import Numerics
import SwiftMPx


//
// Make MPFloat conform to RealFunctions and ElementaryFunction from Swift-Numerics package
//
extension MPFloat: @retroactive RealFunctions {}
extension MPFloat: @retroactive ElementaryFunctions {}

//
// Make MPFloat conform to PreciseFloatingPoint
//
extension MPFloat : PreciseFloatingPoint {
    
    typealias CT = MPComplex

    public static var precisionTag: PrecisionTag { .mpfloat }
    
    public static var zero: MPFloat { MPFloat(0) }
    
    /// Convert MPFloat to MPFloat
    public var asMPFloat: MPFloat { self }
    
    /// Convert MPFloat to Double
    public var asDouble: Double { Double(self.toDouble()) }
    
    /// Convert to MPFloat
    @inline(__always)
    public func toMPFloat(precision: Int) -> MPFloat {
        MPFloat(self, precision: precision)
    }
    
    /// Check if absolute difference between two values is less or equal a tolerance value
    /// - Parameters:
    ///   - other: 2nd value
    ///   - tolerance: Tolerance. Default = 0: Identical with ==
    /// - Returns: true if values are almost equal
    @inline(__always)
    public func almostEqual(to other: MPFloat, tolerance: MPFloat) -> Bool {
        MPFloat.abs(self - other) < tolerance
    }
    
}

