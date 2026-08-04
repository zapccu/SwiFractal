//
//  LinAlgebra.swift
//
//  Created by Dirk Braner on 15.11.24.
//

import Foundation
import Numerics

// ------------------------------------
//  Arithmetic functions
// ------------------------------------

extension BinaryFloatingPoint {
    
    /// Operator for modulo division of floating point values
    static func % (_ lhs: Self, _ rhs: Self) -> Self {
        return lhs.truncatingRemainder(dividingBy: rhs)
    }
    
}

/// Convert degree to radian
func deg2rad(_ deg: Double) -> Double {
    return Double.pi * deg / 180.0
}
