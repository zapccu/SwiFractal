//
//  Interpolation.swift
//  SwiFractal
//
//  Implement interpolation functions for Double, Float, SIMD3 and SIMD4.
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

    /// Cubic interpolation
    public static func interpolateCubic(edge0: Self, edge1: Self, x: Self) -> Self {
        // map x into [0, 1]
        // If x < edge0: t = 0; if x > edge1: t = 1
        let t = min(max((x - edge0) / (edge1 - edge0), 0.0), 1.0)
        
        // Cubic Hermite interpolation
        return t * t * (3.0 - 2.0 * t)
    }
    
    /// Create an array with linear distributed foating point values
    /// - Parameters:
    ///   - start: First value of array
    ///   - end: Last value of array
    ///   - n: Number of values in array
    /// - Returns: Array of size n
    public static func linspace(_ start: Self, _ end: Self, _ n: Int) -> [Self] {
        guard n > 0 else { return [] }
        let step = (end - start) / Self(n - 1)
        var a = Array(0..<n).map { Self($0) * step + start }
        
        // Prevent rounding errors for last array element
        if n > 1 { a[n-1] = end }
        
        return a
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
