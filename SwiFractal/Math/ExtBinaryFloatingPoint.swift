//
//  Helpers.swift
//  SwiFractal
//
//  Created by Dirk Braner on 27.08.26.
//

import Foundation


extension BinaryFloatingPoint {


    /// Convert degree to radian
    @inline(__always)
    public var deg2rad: Self {
        Self.pi * self / 180.0
    }
    
    /// Fast power function for integer exponents
    /// - Parameter exponent: Exponent
    /// - Returns: Power to exponent

    
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
