//
//  Clamping.swift
//  SwiFractal
//
//  Created by Dirk Braner on 27.08.26.
//

import Foundation


///
/// Clamping for Int
///
extension Int {
    
    /// Map value to boundaries
    /// - Parameter range: Closed range
    /// - Returns: Mapped value
    @inline(__always)
    public func clamped(to range: ClosedRange<Int>) -> Int {
        return Swift.max(range.lowerBound, Swift.min(range.upperBound, self))
    }
    
}

extension Double {
    
    /// Return value clamped to range 0...1
    public var clamped: Double {
        return Swift.max(Swift.min(self, 1.0), 0.0)
    }
    
    /// Map value to boundaries
    /// - Parameter range: Closed range
    /// - Returns: Mapped value
    @inline(__always)
    public func clamped(to range: ClosedRange<Double>) -> Double {
        return Swift.max(range.lowerBound, Swift.min(range.upperBound, self))
    }
    
}

extension Float {
    
    /// Return value clamped to range 0...1
    public var clamped: Float {
        return max(min(self, 1.0), 0.0)
    }
    
    /// Map value to boundaries
    /// - Parameter range: Closed range
    /// - Returns: Mapped value
    @inline(__always)
    public func clamped(to range: ClosedRange<Float>) -> Float {
        return Swift.max(range.lowerBound, Swift.min(range.upperBound, self))
    }
    
}

extension SIMD3 where Scalar == Double {
    
    /// Return value clamped to range 0...1
    public var clamped: SIMD3<Double> {
        return self.clamped(to: 0.0...1.0)
    }
    
    /// Map value to boundaries
    /// - Parameter range: Closed range
    /// - Returns: Mapped value
    @inline(__always)
    public func clamped(to range: ClosedRange<Double>) -> SIMD3<Double> {
        return SIMD3<Double>(x: self.x.clamped(to: range), y: self.y.clamped(to: range), z: self.z.clamped(to: range))
    }
    
}

extension SIMD3 where Scalar == Float {
    
    /// Return value where components x,y,z clamped to range 0...1
    public var clamped: SIMD3<Float> {
        return self.clamped(to: 0.0...1.0)
    }
    
    /// Map components x,y,z of value to boundaries
    /// - Parameter range: Closed range
    /// - Returns: Mapped value
    @inline(__always)
    public func clamped(to range: ClosedRange<Float>) -> SIMD3<Float> {
        return SIMD3<Float>(x: self.x.clamped(to: range), y: self.y.clamped(to: range), z: self.z.clamped(to: range))
    }
    
}

extension SIMD4 where Scalar == Double {
    
    /// Return value where components x,y,z,w clamped to range 0...1
    public var clamped: SIMD4<Double> {
        return self.clamped(to: 0.0...1.0)
    }

    /// Map components x,y,z,w of value to boundaries
    /// - Parameter range: Closed range
    /// - Returns: Mapped value
    @inline(__always)
    public func clamped(to range: ClosedRange<Double>) -> SIMD4<Double> {
        return SIMD4<Double>(x: x.clamped(to: range), y: y.clamped(to: range), z: z.clamped(to: range), w: w.clamped(to: range))
    }
    
}

extension SIMD4 where Scalar == Float {
    
    /// Return value where components x,y,z,w clamped to range 0...1
    public var clamped: SIMD4<Float> {
        return self.clamped(to: 0.0...1.0)
    }

    /// Map components x,y,z,w of value to boundaries
    /// - Parameter range: Closed range
    /// - Returns: Mapped value
    @inline(__always)
    public func clamped(to range: ClosedRange<Float>) -> SIMD4<Float> {
        return SIMD4<Float>(x: x.clamped(to: range), y: y.clamped(to: range), z: z.clamped(to: range), w: w.clamped(to: range))
    }
    
}
