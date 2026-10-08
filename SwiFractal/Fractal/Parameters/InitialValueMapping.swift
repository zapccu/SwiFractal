//
//  InitialValueMapping.swift
//  SwiFractal
//
//  Created by Dirk Braner on 07.10.26.
//

import Foundation


///
/// Maps a pixel coordinate to (z0, c). Contains only the constants needed.
///
nonisolated struct InitialValueMapping<CT: ComplexNumber>: Sendable {
    
    /// The fractal kind
    let kind: FractalKindID
    
    /// Mandelbrot: z0 (= zero), Julia: c
    let constant: CT
    
    /// Return start values z0 and c for iteration depending on fractal kind
    /// - Parameter v: Variable value, usually complex point C
    /// - Returns: Tuple (z0, c)
    @inline(__always)
    func values(for v: CT) -> (z0: CT, c: CT) {
        switch kind {
        case .mandelbrot: return (constant, v)
        case .julia:      return (v, constant)
        }
    }
    
}
