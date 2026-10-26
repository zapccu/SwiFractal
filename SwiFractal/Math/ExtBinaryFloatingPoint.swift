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

}
