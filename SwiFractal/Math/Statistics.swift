//
//  Statistics.swift
//  SwiFractal
//
//  Created by Dirk Braner on 26.03.26.
//

import Foundation

// Calculate exponential moving average (EMA) with weight on new value (newValue)
//
// Formula: St = a * Xt + (1 - a) * St-1
//   St = New average
//   Xt = Current value
//   a = Smoothing factor (0-1)
//
// Parameters:
//
//   previousAvg - Previous average value
//   smooth - Smoothing factor (0-1)
//   newValue - New measure / value
//
// Returns:
//
//   New average value
//
func expMovAvg(newValue: Double, smooth: Double, previousAvg: Double) -> Double {
    return smooth * newValue + (1.0 - smooth) * previousAvg
}

// Calculate exponential moving average (EMA) with weight on previous average (previousAvg)
//
// Formula: St = a * Xt + (1 - a) * St-1
//   St = New average
//   Xt = Current value
//   a = Smoothing factor (0-1)
//
// Parameters:
//
//   previousAvg - Previous average value
//   smooth - Smoothing factor (0-1)
//   newValue - New measure / value
//
// Returns:
//
//   New average value
//
func expMovAvg(previousAvg: Double, smooth: Double, newValue: Double, smoothIter: Double = 1.0) -> Double {
    return (1.0 + smoothIter * (smooth - 1.0)) * previousAvg + smoothIter * (1.0 - smooth) * newValue
}

// BIAS correction
//
// Standard formula: St = St / (1 - b ^ t)
// Enhanced formula: St = St / (1 - b ^ t * (1 + s * (b - 1)))
//   St = Average
//   b = Smoothing factor (0-1)
//   t = Timestep (= iteration count)
//   s = Timestep (= smooth iteration count)
//
// We are using the enhanced formula because the last step t is incomplete.
// (1 + s * (b - 1)) is the part of the weight contributed by the last step.
//
// Parameters:
//
//   peviousAvg - Previus average value.
//   smooth - Smoothing factor (0-1)
//   iter - Iteration count when bailout has been reached
//   smoothIter - Smooth iteration count
//
// Returns:
//
//   New average value.
//
func biasCorrect(previousAvg: Double, smooth: Double, iter: Int, smoothIter: Double) -> Double {
    return previousAvg / (1.0 - pow(smooth, Double(iter)) * (1.0 + smoothIter * (smooth - 1.0)))
}
