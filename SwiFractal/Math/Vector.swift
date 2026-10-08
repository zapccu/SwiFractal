//
//  Vector.swift
//  SwiFractal
//
//  Created by Dirk Braner on 29.03.26.
//

import Foundation
import Numerics

///
/// Vector type
///
struct Vector<E> : ExpressibleByArrayLiteral, Sendable where E: Numeric, E: Sendable {
    
    typealias ArrayLiteralElement = E
    
    var array: [E] = []
    
    /// Return Vector dimension (equal to size)
    var dim: Int { array.count }
    
    /// Return Vector size (equal to dimension)
    var size: Int { array.count }
    
    /// Initialize an empty vector
    init() {
    }
    
    /// Initialize vector with array literal
    init(arrayLiteral elements: ArrayLiteralElement...) {
        self.array = elements
    }
    
    /// Initialize vector with array of elements
    init(_ elements: [E]) {
        self.array = elements
    }
    
    /// Initialize vector with dimension and default value
    init(_ dim: Int, defaultValue: E) {
        self.array = Array(repeating: defaultValue, count: dim)
    }
    
    /// Access vector element
    subscript(i: Int) -> E {
        get {
            assert(i < array.count, "Index out of bounds")
            return array[i]
        }
        set {
            assert(i < dim, "Index out of bounds")
            array[i] = newValue
        }
    }
    
    /// Convert Vector elements from Float to Double
    func toDouble() -> Vector<Double> where E == Float {
        .init(array.map { Double($0) })
    }
    
    /// Convert vector elements from Double to Float
    func toFloat() -> Vector<Float> where E == Double {
        .init(array.map { Float($0) })
    }
    
    /// Multiply two vectors (dot product)
    static func * (_ lhs: Vector<E>, _ rhs: Vector<E>) -> E {
        var s: E = .zero
        assert(lhs.dim == rhs.dim, "Vectors must have same dimension")
        
        for i in 0..<lhs.dim {
            s = s + lhs[i] * rhs[i]
        }
        
        return s
    }
    
    /// Multiply vector by scalar
    static func * (_ lhs: Vector<E>, _ rhs: E) -> Vector<E> {
        let arr = lhs.array.map { $0 * rhs }
        return Vector<E>(arr)
    }
    
}

extension Vector where E: PreciseFloatingPoint {
    
    /// Create vector with linear distributed precise floating point values
    /// - Parameters:
    ///   - dim: size of vector
    ///   - start: first value
    ///   - end: last value
    init(_ dim: Int, start: E, end: E) {
        self.array = E.linspace(start, end, dim)
    }
    
    /// Divide vector by scalar
    static func / (_ lhs: Vector<E>, _ rhs: E) -> Vector<E> {
        let arr = lhs.array.map { $0 / rhs }
        return Vector<E>(arr)
    }
    
}
