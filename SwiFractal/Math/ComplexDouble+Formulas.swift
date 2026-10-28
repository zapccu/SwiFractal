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
    
    /// Calculate first derivation of Z, in place. Must be called with Z of the current iteration (before squareAdd)
    /// D = 2·D·Z + 1 for Mandelbrot, D = 2·D·Z for Julia.
    /// - Parameters:
    ///   - z: Current Z before iteration
    ///   - isJulia: True if function called from Julia iteration
    ///   - scratch: Not used
    @inline(__always)
    public mutating func derivativeStep(z: Cplx, isJulia: Bool, scratch: inout Void) {
        self = isJulia
            ? Complex(2 * (real * z.real - imaginary * z.imaginary),
                            2 * (real * z.imaginary + imaginary * z.real))
            : Complex(2 * (real * z.real - imaginary * z.imaginary) + 1,
                            2 * (real * z.imaginary + imaginary * z.real))
    }
    
    /// Calculate z = z² + c, in place.
    /// - Parameters:
    ///   - c: Current complex point
    ///   - scratch: Not used
    @inline(__always)
    public mutating func squareAdd(_ c: Cplx, scratch: inout Void) {
        self = self.squared + c
    }
    
    /// Calculate z = z² + c, in place.
    /// - Parameters:
    ///   - c: Current complex point
    @inline(__always)
    public mutating func squareAdd(_ c: Cplx) {
        self = self.squared + c
    }
    
    /// Calculate z = z², in place.
    /// - Parameter scratch: Not used
    @inline(__always)
    public mutating func square(scratch: inout Void) {
        self = self.squared
    }
    
}
