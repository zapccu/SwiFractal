//
//  MPComplex+ComplexNumber.swift
//  SwiFractal
//
//  Created by Dirk Braner on 25.10.26.
//

import Foundation
import SwiftMPx


///
/// Make MPComplex conform to ComplexNumber protocol
///
extension MPComplex: ComplexNumber {
    
    typealias RT = MPFloat
    typealias Scratch = MPFloat
    
    static func zero(precision: Int) -> MPComplex {
        return MPComplex(0.0, 0.0, precision: precision)
    }
    
    /// Convert MPComplex to Cplx (Complex Double)
    func toCplx() -> Cplx {
        return Cplx(real.toDouble(), imaginary.toDouble())
    }
    
    /// Change precision of MPComplex value
    /// - Parameter precision: Mantissa precision (bits)
    /// - Returns: new MPComplex value with specified precision
    func toMPComplex(precision: Int) -> MPComplex {
        return MPComplex(real, imaginary, precision: precision)
    }
    
    /// Test if `(self - other).lengthSquared < tolerance`
    /// - Parameters:
    ///   - other: Other value
    ///   - tolerance: Tolerance
    /// - Returns: true if values are almost equal
    func almostEqual(to other: MPComplex, tolerance: MPFloat) -> Bool {
        let diff = self - other
        return diff.lengthSquared < tolerance
    }
    
}

