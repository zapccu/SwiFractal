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

/// Modulo division of floating point values
func %<T: BinaryFloatingPoint>(_ lhs: T, _ rhs: T) -> T {
    return lhs.truncatingRemainder(dividingBy: rhs)
}

/*

/// Dot product of two vectors
func mulDot<T: BinaryFloatingPoint>(_ lhs: [T], _ rhs: [T]) -> T {
    var s: T = 0
    guard lhs.count == rhs.count else { return .nan }
    
    for i in 0..<lhs.count {
        s = s + lhs[i] * rhs[i]
    }
    
    return s
}

/// Dot product of two vectors
func mulDot(_ lhs: Vector3, _ rhs: Vector3) -> Double {
    return lhs.x * rhs.x + lhs.y * rhs.y + lhs.z * rhs.z
}

 */

/// Convert degree to radian
func deg2rad(_ deg: Double) -> Double {
    return Double.pi * deg / 180.0
}
