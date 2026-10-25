//
//  ComplexDouble+Formulas.swift
//  SwiFractal
//
//  Created by Dirk Braner on 25.10.26.
//


import Foundation
import Numerics
import SwiftMPx


extension Complex<Double> {
    
    typealias Scratch = Void

    /// Satisfy protocol requirement
    @inline(__always)
    public static func makeScratch(precision: Int) -> Void { () }
    
    /// Calculate D = 2·D·Z + 1, in place. Must be called with Z of the current iteration (before formSquareAdd)
    /// - Parameters:
    ///   - z: Current Z before iteration
    ///   - scratch: Not used
    @inline(__always)
    public mutating func formDerivativeStep(z: Cplx, scratch: inout Void) {
        self = Complex(2 * (real * z.real - imaginary * z.imaginary) + 1,
                            2 * (real * z.imaginary + imaginary * z.real))
    }
    
    /// Calculate z = z² + c, in place.
    /// - Parameters:
    ///   - c: Current complex point
    ///   - scratch: Not used
    @inline(__always)
    public mutating func formSquareAdd(_ c: Cplx, scratch: inout Void) {
        self = self.squared + c
    }
    
    /// Calculate z = z² + c, in place.
    /// - Parameters:
    ///   - c: Current complex point
    @inline(__always)
    public mutating func formSquareAdd(_ c: Cplx) {
        self = self.squared + c
    }
    
    /// Calculate z = z², in place.
    /// - Parameter scratch: Not used
    @inline(__always)
    public mutating func formSquare(scratch: inout Void) {
        self = self.squared
    }
    
}
