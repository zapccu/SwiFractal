//
//  NumCalc.swift
//
//  Created by Dirk Braner on 15.11.24.
//

import Foundation
import Numerics
//import simd

//
//  Numeric constants
//
struct _NC {
    static let PI2: Double = Double.pi * 2.0
    static let PI12: Double = Double.pi / 2.0
    static let LOG2: Double = log(2.0)
    static let PI180: Double = Double.pi / 180.0
}


// ------------------------------------
//  Complex<Double>
// ------------------------------------

/// Shortcut for Complex type for Double values
typealias Cplx = Complex<Double>

extension Complex<Double>: @retroactive LosslessStringConvertible {
    
    /// Convert String to Complex
    /// String format: FloatingPoint[+FloatingPoint["i"]]
    public init? (_ str: String) {
        var s = str
        
        if s.last == "i" { s.removeLast() }
        let parts = s.split(separator: "+")
        guard parts.count == 1 || parts.count == 2 else { return nil }
        
        if parts.count == 1, let r = Double(parts[0]) {
            self.init(r, 0.0)
        }
        else if parts.count == 2, let r = Double(parts[0]), let i = Double(parts[1]) {
            self.init(r, i)
        }
        else {
            return nil
        }
    }
    
    /// Return complex value as String
    var description: String {
        return "\(real)+\(imaginary)i"
    }
    
    // Return real * real + imaginary * imaginary
    var norm: Double {
        return lengthSquared
    }
    
    // Return sqrt(real * real + imaginary * imaginary)
    var abs: Double {
        return length
    }
    
    /// Return minimum of real and imaginary part
    var min: Double {
        return min(real, imaginary)
    }
    
    /// Return maximum of real and imaginary part
    var max: Double {
        return min(real, imaginary)
    }
    
    /// Return epsilon
    var ulp: Double {
        return max(real.ulp, imaginary.ulp)
    }
    
    /// Multiply Cplx with Double
    static func * (lhs: Cplx, rhs: Double) -> Cplx {
        return lhs * Cplx(rhs)
    }

    /// Multiply Double with Cplx
    static func * (lhs: Double, rhs: Cplx) -> Cplx {
        return Cplx(lhs) * rhs
    }

    /// Divide Cplx by Double
    static func / (lhs: Cplx, rhs: Double) -> Cplx {
        return lhs / Cplx(rhs)
    }

    /// Divide Double by Cplx
    static func / (lhs: Double, rhs: Cplx) -> Cplx {
        return Cplx(lhs) / rhs
    }

    /// Add Cplx to Double
    static func + (lhs: Cplx, rhs: Double) -> Cplx {
        return lhs + Cplx(rhs)
    }

    /// Add Double to Cplx
    static func + (lhs: Double, rhs: Cplx) -> Cplx {
        return Cplx(lhs) + rhs
    }

    /// Subtract Double from Cplx
    static func - (lhs: Cplx, rhs: Double) -> Cplx {
        return lhs - Cplx(rhs)
    }
    
    /// Subtract Cplx from Double
    static func - (lhs: Double, rhs: Cplx) -> Cplx {
        return Cplx(lhs) - rhs
    }
}

extension String {
    /// Convert Cplx to String
    init (_ c: Cplx) {
        self = c.description
    }
}


//  SIMD Double vectors
typealias Vector = SIMD3<Double>


// ------------------------------------
//  Linear spacing functions
// ------------------------------------

/// Create an array with linear distributed foating point values
func linspace<T: FloatingPoint>(_ start: T, _ end: T, _ n: Int) -> [T] {
    guard n > 0 else { return [] }
    let step = (end - start) / T(n - 1)
    var a = Array(0..<n).map { T($0) * step + start }
    
    // Prevent rounding errors for last array element
    if n > 1 { a[n-1] = end }
    
    return a
}

/// Create an array with linear distributed color values
func linspace(_ start: RGBAColor, _ end: RGBAColor, _ n: Int) -> [RGBAColor] {
    guard n > 0 else { return [] }
    let step = (end - start) / Float(n - 1)
    var a = Array(0..<n).map { step * Float($0) + start }
    
    // Prevent rounding errors for last array element
    if n > 1 { a[n-1] = end }
    
    return a
}

/// Create a matrix with linear distributed complex values
func linspace(_ start: Cplx, _ end: Cplx, _ width: Int, _ height: Int) -> [[Cplx]] {
    guard width > 0 && height > 0 else { return [] }
    let realParts = linspace(start.real, end.real, width)
    let imagParts = linspace(start.imaginary, end.imaginary, height)
    
    // Create an empty matrix
    var a = [[Cplx]](
        repeating: [Cplx](repeating: .zero, count: width),
        count: height
    )
    
    // Initialize matrix
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

/// Modulo division of floating point values
func %<T: BinaryFloatingPoint>(_ lhs: T, _ rhs: T) -> T {
    return lhs.truncatingRemainder(dividingBy: rhs)
}

/// Dot product of matrix and vector for floating point values
func mulDot<T: BinaryFloatingPoint>(_ mat: [[T]], _ vec: [T]) -> [T] {
    guard mat.count == vec.count else { return [] }
    var r: [T] = Array<T>(repeating: 0, count: vec.count)
    
    for i in 0..<mat.count {
        for j in 0..<vec.count {
            r[i] = r[i] + mat[i][j] * vec[j]
        }
    }
    
    return r
}

/// Dot product of two vectors
func mulDot<T: BinaryFloatingPoint>(_ lhs: [T], _ rhs: [T]) -> T {
    var s: T = 0
    guard lhs.count == rhs.count else { return .nan }
    
    for i in 0..<lhs.count {
        s = s + lhs[i] * rhs[i]
    }
    
    return s
}

/// Dot product of two vectors
func mulDot(_ lhs: Vector, _ rhs: Vector) -> Double {
    return lhs.x * rhs.x + lhs.y * rhs.y + lhs.z * rhs.z
}

/// Convert degree to radian
func deg2rad(_ deg: Double) -> Double {
    return Double.pi * deg / 180.0
}
