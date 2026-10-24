//
//  Helpers.swift
//  SwiFractal
//
//  Created by Dirk Braner on 27.08.26.
//

import Foundation


extension BinaryFloatingPoint {
    
    /// Operator for modulo division of floating point values
    @inline(__always)
    public static func % (_ lhs: Self, _ rhs: Self) -> Self {
        return lhs.truncatingRemainder(dividingBy: rhs)
    }
    
    /// Floating point modulo division
    @inline(__always)
    public static func fmod(_ lhs: Self, _ rhs: Self) -> Self {
        return lhs.truncatingRemainder(dividingBy: rhs)
    }

    /// Convert degree to radian
    @inline(__always)
    public var deg2rad: Self {
        Self.pi * self / 180.0
    }
    
    /// Fast power function for integer exponents
    /// - Parameter exponent: Exponent
    /// - Returns: Power to exponent
    public func pow(_ exponent: Int) -> Self {
        guard exponent != 0 else { return 1.0 }
        
        var base = self
        var exp = exponent
        var result: Self = 1.0
            
        if exp < 0 {
            base = 1.0 / base
            exp = -exp
        }
        
        while exp > 0 {
            if exp & 1 == 1 {
                result *= base
            }
            base *= base
            exp >>= 1
        }
        
        return result
    }
    
    /// Check if absolute difference between two values is less or equal a tolerance value
    /// - Parameters:
    ///   - other: 2nd value
    ///   - tolerance: Tolerance. Default = 0: Identical with ==
    /// - Returns: true if values are almost equal
    @inline(__always)
    public func almostEqual(to other: Self, tolerance: Self) -> Bool {
        abs(self - other) < tolerance
    }
    
}
