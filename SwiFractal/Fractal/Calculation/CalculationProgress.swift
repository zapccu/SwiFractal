//
//  CalculationProgress.swift
//  SwiFractal
//
//  Created by Dirk Braner on 16.11.26.
//

import Synchronization   // Atomic: macOS 15 / iOS 18+


///
/// Class for managing the calculation progress
///
nonisolated final class CalculationProgress: Sendable {
    
    /// Done counter
    private let done  = Atomic<Int>(0)
    
    /// Total value
    private let total = Atomic<Int>(1)
    
    /// Pass counter
    private let pass  = Atomic<Int>(0)

    /// Reset progress
    /// - Parameter newTotal: New total value
    func reset(total newTotal: Int) {
        total.store(max(newTotal, 1), ordering: .relaxed)
        done.store(0, ordering: .relaxed)
    }

    /// Add value to done counter
    /// - Parameter n: Value to be added
    @inline(__always)
    func add(_ n: Int) {
        done.add(n, ordering: .relaxed)
    }
    
    /// Set pass counter to value
    /// - Parameter n: Pass number
    @inline(__always)
    func pass(_ n: Int) {
        pass.store(n, ordering: .relaxed)
    }

    /// Return fraction of done from total
    var fraction: Double {
        Double(done.load(ordering: .relaxed)) / Double(total.load(ordering: .relaxed))
    }
    
    /// Return calculation pass number
    var passes: Int { pass.load(ordering: .relaxed) }
    
}

