//
//  PrBinaryFloatingPoint+LERP.swift
//  SwiFractal
//
//  Created by Dirk Braner on 14.08.26.
//

import Foundation


extension BinaryFloatingPoint {
    
    /// Linear interpolation
    /// - Parameters:
    ///   - a: Start value
    ///   - b: End value
    ///   - t: Interpolation factor. Should be in range 0...1
    /// - Returns: Interpolated value
    @inline(__always)
    public static func lerp(a: Self, b: Self, t: Self) -> Self {
        return a + (b - a) * t
    }
    
    /// Exact linear interpolation
    /// - Parameters:
    ///   - a: Start value
    ///   - b: End value
    ///   - t: Interpolation factor. Should be in range 0...1
    /// - Returns: Interpolated value
    @inline(__always)
    public static func lerpExact(a: Self, b: Self, t: Self) -> Self {
        return (1.0 - t) * a + t * b
    }
    
}

extension SIMD3 where Scalar: BinaryFloatingPoint {
    
    @inline(__always)
    public static func lerp(a: Self, b: Self, t: Scalar) -> Self {
        return a + (b - a) * t
    }
    
    @inline(__always)
    public static func lerpExact(a: Self, b: Self, t: Scalar) -> Self {
        return (1.0 - t) * a + t * b
    }
    
}

extension SIMD4 where Scalar: BinaryFloatingPoint {
    
    /// Linear interpolation
    @inline(__always)
    public static func lerp(a: Self, b: Self, t: Scalar) -> Self {
        return a + (b - a) * t
    }
    
    /// Linear interpolation
    @inline(__always)
    public static func lerpExact(a: Self, b: Self, t: Scalar) -> Self {
        return (1.0 - t) * a + t * b
    }
    
    /// Cosine interpolation
    @inline(__always)
    public static func cosineInterpolate(a: Self, b: Self, t: Scalar) -> Self {
        let tCos = t * Scalar.pi
        let tSmooth = (Scalar(1.0) - tCos) * Scalar(0.5)
        return lerp(a: a, b: b, t: tSmooth)
    }
    
    /// Linear spacing
    public static func linspace(a: Self, b: Self, count: Int) -> [Self] {
        guard count > 0 else { return [] }
        let step = (b - a) / Scalar(count - 1)
        var arr = Array(0..<count).map { step * Scalar($0) + a }
        
        // Prevent rounding errors for last array element
        if count > 1 { arr[count-1] = b }
        
        return arr
    }
        
}
