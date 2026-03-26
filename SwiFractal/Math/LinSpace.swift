//
//  LinSpace.swift
//  SwiFractal
//
//  Created by Dirk Braner on 26.03.26.
//

import Foundation


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
