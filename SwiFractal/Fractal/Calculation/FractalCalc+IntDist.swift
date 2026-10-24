//
//  FractalCalc+IntDist.swift
//  SwiFractal
//
//  Calculate interior distance to Mandelbrot set boundary
//
//  Created by Dirk Braner on 17.10.26.
//

import Foundation
import SwiftMPx


/// Derivation of f^p(z0, c) nach z0 bzw. c, ausgewertet am Startwert z0.
/*
struct CycleDerivatives<CT> {
    var z: CT      // f^p(z0)
    var dz: CT     // ∂f^p/∂z
    var dc: CT     // ∂f^p/∂c
    var dzz: CT    // ∂²f^p/∂z²
    var dzc: CT    // ∂²f^p/∂z∂c
}
*/

extension FractalCalculation {

    typealias CycleDerivatives = (z: CT, dz: CT, dc: CT, dzz: CT, dzc: CT)

    /// p iterations of z → z² + c, dabei werden die Ableitungen mitgeführt.
    /// Order of updates is important! Old values on the right hand side.
    @inline(__always)
    nonisolated static func iterateCycle(from z0: CT, c: CT, period p: Int) -> CycleDerivatives {
        let zero = CT.zero(precision: c.precision)
        let one = CT(1.0, 0.0, precision: c.precision)
        let two = CT(2.0, 0.0, precision: c.precision)
        var z = z0
        var dz = one
        var dc = zero
        var dzz = zero
        var dzc = zero
        for _ in 0..<p {
            let ndzz = two * (dz * dz + z * dzz)
            let ndzc = two * (dc * dz + z * dzc)
            let ndc  = two * z * dc + one
            let ndz  = two * z * dz
            z = z * z + c
            dz = ndz; dc = ndc; dzz = ndzz; dzc = ndzc
        }
        return (z: z, dz: dz, dc: dc, dzz: dzz, dzc: dzc)
    }
    
    /// Interior Distance Estimation (Mandelbrot, Parameterebene).
    /// - Parameters:
    ///   - C: Complex pixel coordinate
    ///   - Zn: Last Z value of the escape time iteration when pixel has not escaped (start z0 = 0)
    ///   - limits: Fractal calculation limits
    /// - Returns: nil, wenn kein attraktiver Zyklus gefunden wurde (→ wie Rand/unbekannt behandeln)
    nonisolated static func interiorDistance(C: CT, Zn: CT, P: DynamicParameters<PT>) -> MandelbrotResult {
        let one = CT(1.0, 0.0, precision: Zn.precision)
        let tol = P.limits.interiorTolerance * P.limits.interiorTolerance
        let maxPeriod = max(1, min(P.limits.iterations / 10, 512))
        let prefilter: Double = 1e-3    // Threshold for |f^p(zEnd) - zEnd|²
        let newtonSteps: Int = 12
        
        // Periodenkandidaten: Perioden p, bei denen die Bahn nach p Schritten wieder
        // in die Nähe von zEnd kommt. Das ist billig (ein Durchlauf).
        var Z = Zn
        for p in 1...maxPeriod {
            Z = Z.squared + C
            if (Z - Zn).lengthSquared.toDouble() > prefilter { continue }
            
            // Newton auf g(z) = f^p(z) - z, Startwert zEnd (liegt schon nahe am Zyklus)
            Z = Zn
            var converged = false
            for _ in 0..<newtonSteps {
                let r = iterateCycle(from: Z, c: C, period: p)
                let delta = (r.z - Z) / (r.dz - one)
                Z = Z - delta
                if delta.lengthSquared.toDouble() < tol { converged = true; break }
            }
            guard converged else { continue }
            
            // Ableitungen am periodischen Punkt z*
            let r = iterateCycle(from: Z, c: C, period: p)
            let lam2 = r.dz.lengthSquared.toDouble()
            guard lam2 < 1.0 else { continue }          // abstoßender Zyklus → falsche Periode
            
            let denom = (r.dzc + r.dzz * r.dc / (one - r.dz)).length.toDouble()
            guard denom > 0.0 else { continue }
            
            var distance = log((1 - lam2) / denom)
            let lo = P.logPixel
            let hi = P.logMinSize
            distance = (distance - lo) / (hi - lo)
            
            return MandelbrotResult(
                smoothIter: Double(p),      // Length of attractive cycle: smallest p for fᵖ(z*) = z* [1, maxPeriod]
                nZ: sqrt(lam2),             // |λ| of the attractive cycle (0 = center of set, 1 = boundary) [0, 1]
                distance: distance.clamped, // Distance of c to boundary of set (Einheiten der c-Ebene) (0, ≈0.5]
                flags: .inside
            )
        }
        
        return MandelbrotResult.defaultValue
    }
}
