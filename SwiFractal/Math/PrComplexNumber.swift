//
//  PrComplexNumber.swift
//  SwiFractal
//
//  Created by Dirk Braner on 07.05.26.
//

import Numerics
import SwiftMPx


///
/// Protocol for complex numbers
///
protocol ComplexNumber : Sendable {
    
    associatedtype RT: PreciseFloatingPoint
    
    // Placeholders for real and imaginary type
    var real: RT { get }
    var imaginary: RT { get }
    
    // Return squared Euclidean norm: real * real + imaginary * imaginary
    var lengthSquared: RT { get }
    
    // Return Euclidean norm: sqrt(real * real + imaginary * imaginary)
    var length: RT { get }
    
    // Return square
    var squared: Self { get }
    
    // Return angle betweend imaginary and real part
    var arg: RT { get }
        
    // Constructor. Precision is max(real.precision, imaginary.precision)
    init(_ real: RT, _ imaginary: RT)
    
    // Constructor with precision support
    init(_ real: RT, _ imaginary: RT, precision: Int)
    
    // Return zero
    static func zero(precision: Int) -> Self
    
    // Convert to Double precision complex value
    func toCplx() -> Cplx
    
    // Convert to arbitrary precision complex value
    func toMPComplex(precision: Int) -> MPComplex

    // Addition
    static func + (lhs: Self, rhs: Self) -> Self
    static func + (lhs: Self, rhs: RT) -> Self
    static func + (lhs: RT, rhs: Self) -> Self
    
    // Subtraction
    static func - (lhs: Self, rhs: Self) -> Self
    static func - (lhs: Self, rhs: RT) -> Self
    static func - (lhs: RT, rhs: Self) -> Self
    
    // Multiplication
    static func * (lhs: Self, rhs: Self) -> Self
    static func * (lhs: Self, rhs: RT) -> Self
    static func * (lhs: RT, rhs: Self) -> Self
    
    // Division
    static func / (lhs: Self, rhs: Self) -> Self
    static func / (lhs: Self, rhs: RT) -> Self
    static func / (lhs: RT, rhs: Self) -> Self
    
    // Comparison operators
    static func == (lhs: Self, rhs: Self) -> Bool
    static func != (lhs: Self, rhs: Self) -> Bool

}

extension ComplexNumber {
        
    var precision: Int {
        return max(real.precision, imaginary.precision)
    }
        
    /// Return squared magnitude of complex number (squared Euclidean norm)
    var lengthSquared: RT {
        real * real + imaginary * imaginary
    }
    
    /// Return magnitude of complex number (Euclidean norm)
    var length: RT {
        .sqrt(lengthSquared)
    }
    
    /// Return square of complex number
    var squared: Self {
        .init(real * real - imaginary * imaginary, 2.0 * real * imaginary)
    }
    
    /// Return angle betweend imaginary and real part
    var arg: RT {
        RT.atan2(y: imaginary, x: real)
    }
    
    //
    // Addition
    //
    /*
    static func + (lhs: Self, rhs: Self) -> Self {
        .init(lhs.real + rhs.real, lhs.imaginary + rhs.imaginary)
    }
    */
    static func + (lhs: Self, rhs: RT) -> Self {
        .init(lhs.real + rhs, lhs.imaginary)
    }
    
    static func + (lhs: RT, rhs: Self) -> Self {
        .init(lhs + rhs.real, rhs.imaginary)
    }
    
    //
    // Subtraction
    //
    /*
    static func - (lhs: Self, rhs: Self) -> Self {
        .init(lhs.real - rhs.real, lhs.imaginary - rhs.imaginary)
    }
    */
    static func - (lhs: Self, rhs: RT) -> Self {
        .init(lhs.real - rhs, lhs.imaginary)
    }
    
    static func - (lhs: RT, rhs: Self) -> Self {
        .init(lhs - rhs.real, -rhs.imaginary)
    }
    
    //
    // Multiplication
    //
    /*
    static func * (lhs: Self, rhs: Self) -> Self {
        .init(lhs.real * rhs.real - lhs.imaginary * rhs.imaginary,
              lhs.real * rhs.imaginary + lhs.imaginary * rhs.real)
    }
    */
    static func * (lhs: Self, rhs: RT) -> Self {
        .init(lhs.real * rhs, lhs.imaginary * rhs)
    }
    
    static func * (lhs: RT, rhs: Self) -> Self {
        .init(lhs * rhs.real, lhs * rhs.imaginary)
    }
    
    //
    // Division
    //
    /*
    static func / (lhs: Self, rhs: Self) -> Self {
        // Hilfsvariablen zur besseren Lesbarkeit (entspricht der Formel oben)
        let a = lhs.real
        let b = lhs.imaginary
        let c = rhs.real
        let d = rhs.imaginary
        
        let n = (c * c) + (d * d)

        guard n != RT.zero else {
            return .init(RT.nan, RT.nan)
        }
        
        // Berechnung nach der mathematischen Formel
        let nr = ((a * c) + (b * d)) / n
        let ni = ((b * c) - (a * d)) / n
        
        return .init(nr, ni)
    }
    */
    static func / (lhs: Self, rhs: RT) -> Self {
        guard rhs != RT.zero else {
            return .init(RT.nan, RT.nan)
        }
        
        return .init(lhs.real / rhs, lhs.imaginary / rhs)
    }
    
    static func / (lhs: RT, rhs: Self) -> Self {
        let r = lhs
        let c = rhs.real
        let d = rhs.imaginary
        
        let n = (c * c) + (d * d)
        
        // Schutz vor Division durch Null
        guard n != RT.zero else {
            return .init(RT.nan, RT.nan)
        }
        
        let nr = (r * c) / n
        let ni = (-r * d) / n
        
        return .init(nr, ni)
    }
    
    //
    // Comparison operators
    //
    /*
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.real == rhs.real && lhs.imaginary == rhs.imaginary
    }
    static func != (lhs: Self, rhs: Self) -> Bool {
        lhs.real != rhs.real || lhs.imaginary != rhs.imaginary
    }
     */

}

extension MPComplex: ComplexNumber {
    
    typealias RT = MPFloat
    
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
    
}


extension Complex<Double> {
    
    static func zero(precision: Int = 53) -> Complex<Double> {
        .init(0, 0)
    }
    
    func toMPComplex(precision: Int) -> MPComplex {
        return MPComplex(MPFloat(real, precision: precision), MPFloat(imaginary, precision: precision))
    }
    
}



