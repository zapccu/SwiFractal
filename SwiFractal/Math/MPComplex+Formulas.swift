//
//  MPComplex+Formulas.swift
//  SwiFractal
//
//  Created by Dirk Braner on 25.10.26.
//

import Foundation
import SwiftMPx
import CMPFR


///
/// Extend MPComplex by optimized formulas
///
extension MPComplex {
    
    ///
    /// In-place iteration (no allocations)
    ///
    
    /// Create a reusable scratch value. Call once before the iteration loop and reuse it.
    /// - Parameter precision: Precision in bits (ignored by fixed precision types)
    public static func makeScratch(precision: Int) -> MPFloat {
        MPFloat(precision: precision)
    }
    
    /// Calculate z = z² + c, in place.
    /// Intended for hot loops like the calculation of a reference orbit. With a scratch value that is
    /// reused across iterations, no memory is allocated per iteration.
    /// - Parameters:
    ///   - c:       Value to add
    ///   - scratch: Temporary value, reused across calls. Its precision is adjusted to the
    ///              precision of self if necessary (allocation only on first use).
    public mutating func squareAdd(_ c: MPComplex, scratch: inout MPFloat) {
        if scratch.precision != real.precision {
            scratch = MPFloat(precision: real.precision)
        }
        
        // scratch = a² - b², from the original values
        mpfr_fmms(scratch.mutablePtr,
                  real.ptr, real.ptr,
                  imaginary.ptr, imaginary.ptr, MPFR_RNDN)
        
        // imaginary = 2ab + c.imaginary
        mpfr_mul(imaginary.mutablePtr, real.ptr, imaginary.ptr, MPFR_RNDN)
        mpfr_mul_2ui(imaginary.mutablePtr, imaginary.ptr, 1, MPFR_RNDN)
        mpfr_add(imaginary.mutablePtr, imaginary.ptr, c.imaginary.ptr, MPFR_RNDN)
        
        // real = a² - b² + c.real
        mpfr_add(real.mutablePtr, scratch.ptr, c.real.ptr, MPFR_RNDN)
    }
    
    /// Calculate z = z² + c, in place (allocates one temporary value per call)
    public mutating func squareAdd(_ c: MPComplex) {
        var scratch = MPFloat(precision: real.precision)
        squareAdd(c, scratch: &scratch)
    }
    
    /// Calculate z = z², in place. Use predefined scratch value
    public mutating func square(scratch: inout MPFloat) {
        if scratch.precision != real.precision {
            scratch = MPFloat(precision: real.precision)
        }
        mpfr_fmms(scratch.mutablePtr,
                  real.ptr, real.ptr,
                  imaginary.ptr, imaginary.ptr, MPFR_RNDN)
        mpfr_mul(imaginary.mutablePtr, real.ptr, imaginary.ptr, MPFR_RNDN)
        mpfr_mul_2ui(imaginary.mutablePtr, imaginary.ptr, 1, MPFR_RNDN)
        swap(&real, &scratch)
    }
    
    /// Calculate first derivation of Z, in place. Must be called with Z of the current iteration (before squareAdd)
    /// D = 2·D·Z + 1 for Mandelbrot, D = 2·D·Z for Julia.
    /// Rounding: imaginary part 1 rounding (fmma, doubling is exact), real part 2 roundings (fmms, +1).
    /// - Parameters:
    ///   - z:       Current value Z
    ///   - isJulia: True if function called from Julia iteration
    ///   - scratch: Temporary value, reused across calls. Its precision is adjusted to the
    ///              precision of self if necessary. Use the same precision for D and Z to avoid
    ///              reallocations when the same scratch value is used for both steps.
    public mutating func derivativeStep(z: MPComplex, isJulia: Bool, scratch: inout MPFloat) {
        if scratch.precision != real.precision {
            scratch = MPFloat(precision: real.precision)
        }
        
        // scratch = Re(D·Z) = dr·zr − di·zi, from the original values
        mpfr_fmms(scratch.mutablePtr,
                  real.ptr, z.real.ptr,
                  imaginary.ptr, z.imaginary.ptr, MPFR_RNDN)
        
        // Im(D) = 2·(dr·zi + di·zr)
        mpfr_fmma(imaginary.mutablePtr,
                  real.ptr, z.imaginary.ptr,
                  imaginary.ptr, z.real.ptr, MPFR_RNDN)
        mpfr_mul_2ui(imaginary.mutablePtr, imaginary.ptr, 1, MPFR_RNDN)
        
        // Re(D) = 2·Re(D·Z)
        mpfr_mul_2ui(scratch.mutablePtr, scratch.ptr, 1, MPFR_RNDN)
        if !isJulia {
            // Mandelbrot set: Re(D) = Re(D) + 1
            mpfr_add_ui(scratch.mutablePtr, scratch.ptr, 1, MPFR_RNDN)
        }
        
        // New real part is in scratch. The old real part becomes the next scratch value.
        swap(&real, &scratch)
    }
    
    /// Calulate D = 2·D·Z + 1, in place (allocates one temporary value per call)
    public mutating func derivativeStep(z: MPComplex, isJulia: Bool) {
        var scratch = MPFloat(precision: real.precision)
        derivativeStep(z: z, isJulia: isJulia, scratch: &scratch)
    }
    
}
