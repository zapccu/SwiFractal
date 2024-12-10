//
//  NumCalc.swift
//
//  Created by Dirk Braner on 15.11.24.
//

import Numerics
import simd


// ------------------------------------
//  Complex<Double>
// ------------------------------------

// Shortcut for Complex type for Double values
typealias Cplx = Complex<Double>

extension Complex<Double> {
    /// Convert String to Complex
    init (_ str: String) {
        var s = str
        if s.last == "i" {
            s.removeLast()
        }
        let parts = s.split(separator: "+")
        let real = Double(parts[0]) ?? 0
        let imag = Double(parts[1]) ?? 0
        self = Cplx(real, imag)
    }
    
    static func * (lhs: Cplx, rhs: Double) -> Cplx {
        return lhs * Cplx(rhs)
    }

    static func / (lhs: Cplx, rhs: Double) -> Cplx {
        return lhs / Cplx(rhs)
    }

    static func + (lhs: Cplx, rhs: Double) -> Cplx {
        return lhs + Cplx(rhs)
    }

    static func - (lhs: Cplx, rhs: Double) -> Cplx {
        return lhs - Cplx(rhs)
    }
    
    static func abs(_ c: Cplx) -> Double {
        return c.length
    }
    
    static func norm(_ c: Cplx) -> Double {
        return c.lengthSquared
    }
}

extension String {
    /// Convert Cplx to String
    init (_ c: Cplx) {
        self = "\(c.real)+\(c.imaginary)i"
    }
}


// ------------------------------------
//  SIMD Double vectors
// ------------------------------------

typealias Vector = simd_double3


// ------------------------------------
//  Linear spacing functions
// ------------------------------------

func linspace<T: FloatingPoint>(_ start: T, _ end: T, _ n: Int) -> [T] {
    guard n > 0 else { return [] }
    let step = (end - start) / T(n - 1)
    var a = Array(0..<n).map { T($0) * step + start }
    
    // Prevent rounding errors for last array element
    if n > 1 { a[n-1] = end }
    
    return a
}

// Create an array with linear distributed color values
func linspace(_ start: RGBAColor, _ end: RGBAColor, _ n: Int) -> [RGBAColor] {
    guard n > 0 else { return [] }
    let step = (end - start) / Float(n - 1)
    var a = Array(0..<n).map { step * Float($0) + start }
    
    // Prevent rounding errors for last array element
    if n > 1 { a[n-1] = end }
    
    return a
}

// Create a matrix with linear distributed complex values
func linspace(_ start: Cplx, _ end: Cplx, _ width: Int, _ height: Int) -> [[Cplx]] {
    guard width > 0 && height > 0 else { return [] }
    let realParts = linspace(start.real, end.real, width)
    let imagParts = linspace(start.imaginary, end.imaginary, height)
    
    var a = [[Cplx]](
        repeating: [Cplx](repeating: .zero, count: width),
        count: height
    )
    for y in 0..<height {
        for x in 0..<width {
            a[y][x] = Cplx(realParts[x], imagParts[y])
        }
    }
    
    return a
}


// ------------------------------------
//  Arithmetic functions
// ------------------------------------

// Modulo division of floating point values
func %<T: BinaryFloatingPoint>(_ lhs: T, _ rhs: T) -> T {
    return lhs.truncatingRemainder(dividingBy: rhs)
}

// Dot product of matrix and vector for floating point values
func mulDot<T: BinaryFloatingPoint>(_ mat: [[T]], _ vec: [T]) -> [T] {
    guard mat.count == vec.count else { return [] }
    var r: [T] = []
    for i in 0..<mat.count {
        for j in 0..<vec.count {
            r[i] = r[i] + mat[i][j] * vec[j]
        }
    }
    
    return r
}

// Dot product of two vectors
func mulDot<T: BinaryFloatingPoint>(_ lhs: [T], _ rhs: [T]) -> T {
    var s: T = 0
    guard lhs.count == rhs.count else { return .nan }
    
    for i in 0..<lhs.count {
        s = s + lhs[i] * rhs[i]
    }
    
    return s
}

/// Convert degree to radian
func deg2rad(_ deg: Double) -> Double {
    return Double.pi * deg / 180.0
}
