//
//  FractalCalc+Orbits.swift
//  SwiFractal
//
//  Created by Dirk Braner on 31.10.26.
//

import Foundation


///
/// Extend FractalCalculation by orbit detection and period detection
///
/// Structure:
///   1. Detectors (OrbitBuffer, BrentState) deliver a period candidate
///   2. verifyCycle() checks the divisors of the candidate with Newton (refineCycle)
///      and accepts only attracting cycles near Z
///   3. insideResult() builds the MandelbrotResult depending on colorizeInside
///   4. findCycleAfterIteration() is the fallback for points not detected
///      until the iteration limit (slow convergence near the boundary)
///
extension FractalCalculation {

    typealias CycleDerivatives = (z: CT, dz: CT, dc: CT, dzz: CT, dzc: CT)

    // MARK: - Cycle info

    /// Verified attracting cycle
    struct CycleInfo {
        let period: Int                 // Smallest period of the attracting cycle
        let z: CT                       // Cycle point near the current Z (Newton refined)
        let r: CycleDerivatives         // Derivatives of f^period at z
        var absLambda: Double { r.dz.length.toDouble() }    // |λ|: 0 = center, 1 = boundary
    }

    // MARK: - Detector 1: ring buffer

    ///
    /// Ring buffer period detection. Detects periods up to `capacity`.
    ///
    /// Generic over the value type V, independent of CT: the standard iteration uses CT,
    /// the perturbation iteration uses the full Z in Double (Cplx).
    /// The detector only delivers period candidates; verification is done by the caller
    /// via the `verify` closure (in CT precision).
    ///
    struct OrbitBuffer<V: ComplexNumber> {
        private var orbits: [V]
        private let capacity: Int
        private var blockedUntil: Int = 0

        init(Z0: V, capacity: Int) {
            self.capacity = max(capacity, 1)
            orbits = [Z0]
            orbits.reserveCapacity(self.capacity + 1)
        }

        /// - Parameters:
        ///   - i: Current iteration
        ///   - Z: Current Z
        ///   - t1: Detection tolerance (squared)
        ///   - verify: Verifies a period candidate, returns nil if rejected
        /// - Returns: Result of `verify` or nil
        @inline(__always)
        mutating func detect<R>(i: Int, Z: V, t1: Double, verify: (Int) -> R?) -> R? {
            if i >= blockedUntil,
               let index = orbits.lastIndex(where: { ($0 - Z).lengthSquared.toDouble() < t1 }) {
                let candidate = orbits.count - index
                if let result = verify(candidate) { return result }
                blockedUntil = i + 4 * candidate    // Failed: don't verify again in every iteration
            }
            orbits.append(Z)
            if orbits.count > capacity { orbits.removeFirst() }
            return nil
        }
    }

    // MARK: - Detector 2: Brent

    ///
    /// Brent's period detection. Detects any period with O(1) memory.
    /// Generic over the value type V, see OrbitBuffer.
    ///
    struct BrentState<V: ComplexNumber> {
        private var zRef: V
        private var refIter: Int
        private var power: Int = 1
        private var blockedUntil: Int = 0

        /// - Parameters:
        ///   - Z0: Start value of the iteration
        ///   - startIter: First loop index. Z0 belongs to iteration startIter - 1,
        ///                because Z in loop step i is Z_(i+1)
        init(Z0: V, startIter: Int = 0) {
            zRef = Z0
            refIter = startIter - 1
        }

        /// - Parameters:
        ///   - i: Current iteration
        ///   - Z: Current Z
        ///   - t1: Detection tolerance (squared)
        ///   - verify: Verifies a period candidate, returns nil if rejected
        /// - Returns: Result of `verify` or nil
        @inline(__always)
        mutating func detect<R>(i: Int, Z: V, t1: Double, verify: (Int) -> R?) -> R? {
            if i >= blockedUntil, (Z - zRef).lengthSquared.toDouble() < t1 {
                let candidate = i - refIter
                if let result = verify(candidate) { return result }
                blockedUntil = i + 4 * candidate    // Failed: don't verify again in every iteration
            }
            // Renew reference at power-of-2 intervals.
            // Must run independent of blockedUntil, otherwise the schedule breaks.
            if i - refIter >= power {
                zRef = Z
                refIter = i
                power *= 2
            }
            return nil
        }
    }

    /// p iterations of z → z² + c, dabei werden die Ableitungen mitgeführt.
    /// Order of updates is important! Old values on the right hand side.
    @inline(__always)
    nonisolated static func iterateCycle(from z0: CT, c: CT, period p: Int, P: DynamicParameters<PT>) -> CycleDerivatives {
        let zero = P.constantValues.ctZero
        let one = P.constantValues.ctOne
        let two = P.constantValues.ctTwo
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
    
    // MARK: - Verification

    /// Newton refinement of a cycle of period q, starting near Z.
    /// - Returns: Cycle point z* and the full derivatives at z*, or nil if Newton does not converge
    nonisolated static func refineCycle(from Z: CT, C: CT, period q: Int, P: DynamicParameters<PT>) -> (z: CT, r: CycleDerivatives)? {
        guard q >= 1 else { return nil }
        let one = CT(1.0, 0.0, precision: Z.precision)
        var z = Z
        for _ in 0..<P.limits.newtonSteps {
            let r = iterateCycle(from: z, c: C, period: q, P: P)
            let denom = r.dz - one
            if denom.lengthSquared.toDouble() < 1e-20 { return nil }     // λ ≈ 1: parabolic, no decision
            let delta = (r.z - z) / denom
            z = z - delta
            if delta.lengthSquared.toDouble() < P.limits.tNewton {
                return (z, iterateCycle(from: z, c: C, period: q, P: P))       // Derivatives at z*
            }
        }
        return nil
    }

    /// Checks the divisors of the candidate period in ascending order.
    /// - Parameters:
    ///   - Z: Current Z
    ///   - C: Current complex point
    ///   - candidate: Period candidate (may be a multiple of the true period)
    ///   - P: Dynamic calculation parameters (t2, tNewton, newtonSteps)
    /// - Returns: The smallest period with an attracting cycle near Z, or nil
    nonisolated static func verifyCycle(Z: CT, C: CT, candidate p: Int, P: DynamicParameters<PT>) -> CycleInfo? {
        guard p >= 1 else { return nil }
        for q in 1...p where p % q == 0 {
            guard let (z, r) = refineCycle(from: Z, C: C, period: q, P: P) else { continue }
            guard (z - Z).lengthSquared.toDouble() < P.limits.t2 else { continue }  // Orbit is really there
            guard r.dz.lengthSquared.toDouble() < 1.0 else { continue }             // Attracting
            return CycleInfo(period: q, z: z, r: r)
        }
        return nil
    }

    // MARK: - Fallback after the iteration loop

    /// Period search for points that were not detected until the iteration limit.
    /// - Parameters:
    ///   - Zn: Last Z of the iteration
    ///   - C: Current complex point
    ///   - P: Dynamic calculation parameters
    /// - Returns: Verified cycle or nil
    nonisolated static func findCycleAfterIteration(Zn: CT, C: CT, P: DynamicParameters<PT>) -> CycleInfo? {
        let maxPeriod = max(1, min(P.limits.iterations / 10, 512))
        let prefilter = 4.0 * P.limits.t2      // |f^p(Zn) - Zn| ≈ |λ^p - 1|·|Zn - z*| ≤ 2·|Zn - z*|

        var w = Zn                              // Own loop variable, Zn stays untouched
        for p in 1...maxPeriod {
            w = w.squared + C
            guard (w - Zn).lengthSquared.toDouble() < prefilter else { continue }
            if let cycle = verifyCycle(Z: Zn, C: C, candidate: p, P: P) {
                return cycle
            }
        }
        return nil
    }

    // MARK: - Results

    /// Continuous iteration count: iteration at which the orbit came closer than ε to the cycle.
    /// Independent of when the detector noticed the cycle (important for Brent).
    nonisolated static func smoothConvergence(i: Int, Z: CT, cycle: CycleInfo, P: DynamicParameters<PT>) -> Double {
        let eps  = sqrt(P.limits.t1)                       // Detection distance
        let d    = (Z - cycle.z).length.toDouble()
        let absL = cycle.absLambda
        var smooth = Double(i)
        if d > 0, absL > 0, absL < 1 {
            smooth += Double(cycle.period) * log(eps / d) / log(absL)
        }
        return max(smooth, 0.0)
    }

    /// Interior distance estimate, normalized for color mapping.
    nonisolated static func interiorDistance(_ cycle: CycleInfo, P: DynamicParameters<PT>) -> Double? {
        let r = cycle.r
        let one = CT(1.0, 0.0, precision: r.dz.precision)
        let lam2 = r.dz.lengthSquared.toDouble()
        let denom = (r.dzc + r.dzz * r.dc / (one - r.dz)).length.toDouble()
        guard denom > 0.0 else { return nil }
        let d = log((1 - lam2) / denom)
        return ((d - P.logPixel) / (P.logMinSize - P.logPixel)).clamped
    }

    /// Builds the result for a point inside the set, depending on colorizeInside.
    ///
    /// Field usage (unchanged from previous versions):
    ///   .distance:              smoothIter = period,          nZ = |λ|, distance = interior distance
    ///   .orbits / .brentOrbits: smoothIter = smooth iteration, nZ = |λ|, distance = period
    nonisolated static func insideResult(i: Int, Z: CT, cycle: CycleInfo, P: DynamicParameters<PT>) -> MandelbrotResult {
        if P.colorizeInside == .distance {
            return MandelbrotResult(
                smoothIter: Double(cycle.period),
                nZ: cycle.absLambda,
                distance: interiorDistance(cycle, P: P) ?? 0.0,
                flags: [.inside]
            )
        }
        return MandelbrotResult(
            smoothIter: smoothConvergence(i: i, Z: Z, cycle: cycle, P: P),
            nZ: cycle.absLambda,
            distance: Double(cycle.period),
            flags: [.inside]
        )
    }
}
