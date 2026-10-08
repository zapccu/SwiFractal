//
//  Clamping.swift
//  SwiFractal
//
//  Created by Dirk Braner on 27.08.26.
//

import Foundation

extension BinaryInteger {
    
    /// Map value to boundaries
    /// - Parameter range: Closed range
    /// - Returns: Mapped value
    @inline(__always)
    public func clamped(to range: ClosedRange<Self>) -> Self {
        return Swift.max(range.lowerBound, Swift.min(range.upperBound, self))
    }
    
}

extension BinaryFloatingPoint {
    
    /// Return value clamped to range 0...1
    public var clamped: Self {
        return self.clamped(to: 0.0...1.0)
    }
    
    /// Map value to boundaries
    /// - Parameter range: Closed range
    /// - Returns: Mapped value
    @inline(__always)
    public func clamped(to range: ClosedRange<Self>) -> Self {
        return Swift.max(range.lowerBound, Swift.min(range.upperBound, self))
    }
    
}

extension SIMD3 where Scalar: BinaryFloatingPoint {
    
    /// Return value clamped to range 0...1
    public var clamped: Self {
        return self.clamped(to: 0.0...1.0)
    }
    
    @inline(__always)
    public func clamped(to range: ClosedRange<Scalar>) -> Self {
        return Self(x: self.x.clamped(to: range), y: self.y.clamped(to: range), z: self.z.clamped(to: range))
    }
    
}

extension SIMD4 where Scalar: BinaryFloatingPoint {
    
    /// Return value clamped to range 0...1
    public var clamped: Self {
        return self.clamped(to: 0.0...1.0)
    }

    /// Map value to boundaries
    /// - Parameter range: Closed range
    /// - Returns: Mapped value
    @inline(__always)
    public func clamped(to range: ClosedRange<Scalar>) -> Self {
        return Self(x: x.clamped(to: range), y: y.clamped(to: range), z: z.clamped(to: range), w: w.clamped(to: range))
    }
    
}
