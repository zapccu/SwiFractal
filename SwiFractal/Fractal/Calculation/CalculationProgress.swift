//
//  CalculationProgress.swift
//  SwiFractal
//
//  Created by Dirk Braner on 16.11.26.
//

import Synchronization   // Atomic: macOS 15 / iOS 18+


nonisolated final class CalculationProgress: Sendable {
    
    private let done  = Atomic<Int>(0)
    private let total = Atomic<Int>(1)
    private let pass  = Atomic<Int>(0)

    func reset(total newTotal: Int) {
        total.store(max(newTotal, 1), ordering: .relaxed)
        done.store(0, ordering: .relaxed)
    }

    @inline(__always)
    func add(_ n: Int) {
        done.add(n, ordering: .relaxed)
    }
    
    @inline(__always)
    func pass(_ n: Int) {
        pass.store(n, ordering: .relaxed)
    }

    var fraction: Double {
        Double(done.load(ordering: .relaxed)) / Double(total.load(ordering: .relaxed))
    }
    
    /// Return calculation pass number
    var passes: Int { pass.load(ordering: .relaxed) }
    
}

