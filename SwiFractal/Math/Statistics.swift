//
//  Statistics.swift
//  SwiFractal
//
//  Created by Dirk Braner on 26.03.26.
//

import Foundation


/// Calculate exponential moving average (EMA) with weight on new value (newValue)
/// - Parameters:
///   - newValue: New measure / value
///   - smooth: Smoothing factor in range 0...1
///   - previousAvg: Previous average value
/// - Returns: New average value
///
/// - Formula: `St = a * Xt + (1 - a) * St-1`\
///   St = New average\
///   Xt = Current value\
///   a = Smoothing factor (0-1)
@inline(__always)
func expMovAvg(newValue: Double, smooth: Double, previousAvg: Double) -> Double {
    return smooth * newValue + (1.0 - smooth) * previousAvg
}

/// Calculate exponential moving average (EMA) with weight on on previous average (previousAvg)
/// - Parameters:
///   - previousAvg: Previous average value
///   - smooth: Smoothing factor in range 0...1
///   - newValue: New measure / value
///   - smoothIter: Optional smooth iteration factor in range 0...1. Default = 1.0
/// - Returns: New average value
@inline(__always)
func expMovAvg(previousAvg: Double, smooth: Double, newValue: Double, smoothIter: Double = 1.0) -> Double {
    // stripeAvg * (1.0 + smoothIter * (P.MP.stripeSig - 1.0)) + stripet * smoothIter * (1.0 - P.MP.stripeSig)
    return (1.0 + smoothIter * (smooth - 1.0)) * previousAvg + smoothIter * (1.0 - smooth) * newValue
}

/// BIAS correction
/// - Parameters:
///   - previousAvg: Previous average value
///   - smooth: Smoothing factor in range 0...1
///   - iter: Iteration count when bailout has been reached
///   - smoothIter: Smooth iteration count
/// - Returns: New average value
///
/// Standard formula: `St = St / (1 - b ^ t)`\
/// Enhanced formula: `St = St / (1 - b ^ t * (1 + s * (b - 1)))`\
/// St = Average\
/// b = Smoothing factor (0-1)\
/// t = Timestep (= iteration count)\
/// s = Timestep (= smooth iteration count)
///
/// We are using the enhanced formula because the last step *t* is incomplete.
/// `(1 + s * (b - 1))` is the part of the weight contributed by the last step.
@inline(__always)
func biasCorrect(previousAvg: Double, smooth: Double, iter: Int, smoothIter: Double) -> Double {
    let denom = (1.0 - smooth.pow(iter) * (1.0 + smoothIter * (smooth - 1.0)))
    guard denom > 1e-12 else { return previousAvg }
    return previousAvg / denom
}
