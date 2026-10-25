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

