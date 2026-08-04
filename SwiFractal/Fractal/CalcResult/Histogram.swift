//
//  Histogram.swift
//  SwiFractal
//
//  Created by Dirk Braner on 04.07.26.
//

//
// Histogram of calculation result matrix
//
struct Histogram {
    
    // Cumulative, normalized values per iteration count, index 0...maxHistValue (maxValue - 1).
    // cumulative[i] indicates the proportion of all "escaped" pixels that have an iteration count <= i.
    private var cumulative: [Double] = []

    /// Maximum histogram value of an element in result matrix == maxValue - 1.
    let maxHistValue: Int
    
    /// Number of result matrix elements matching histogram criteria.
    /// If no element is matching the histogram criteria, all pixels must be set to default color.
    var escapedCount: Int

    /// Create histogram from result matrix.
    /// - Parameters:
    ///   - result: Result matrix
    ///   - maxValue: Maximum calculation value. For Mandelbrot set this is equal to maxIterations.
    init(result: Matrix<MandelbrotResult>, maxValue: Int) {
        self.maxHistValue = maxValue - 1
        self.escapedCount = 0

        // Count results with same result value (i.e. iteration count).
        // Result value must be < maxValue and result.isValidHistValue must be true.
        var counts: [Int] = Array(repeating: 0, count: maxValue)

        for row in 0..<result.rows {
            for col in 0..<result.cols {
                let element: MandelbrotResult = result[row, col]

                // Count only elements containing valid histogram values
                if element.hasValidHistValue  {
                    // Value must fit into array bounds
                    let stage = min(Int(element.histValue), maxHistValue)
                    counts[stage] += 1
                    escapedCount += 1
                }
            }
        }
        
        if escapedCount == 0 {
            // Result matrix does not contain any histogram values
            self.cumulative = Array(repeating: 0.0, count: maxValue)
            return
        }

        // Build cumulative sum
        var cumulativeCounts: [Int] = Array(repeating: 0, count: maxValue)
        var running = 0
        
        for i in 0..<maxValue {
            running += counts[i]
            cumulativeCounts[i] = running
        }

        // Normalize to [0, 1]
        self.cumulative = cumulativeCounts.map { Double($0) / Double(escapedCount) }
    }

    /// Normalized color value in range 0...1 for a given result value (i.e. smoothIter for Mandelbrot results)
    /// with linear interpolation between surrounding iteration steps for smooth coloring.
    /// - Parameter result: Calculation result
    /// - Returns: Normalized color value in range 0...1.
    func normalize(_ result: MandelbrotResult) -> Double {
        let clamped = max(0.0, result.histValue)
        let lower = min(Int(clamped.rounded(.down)), maxHistValue)
        let upper = min(lower + 1, maxHistValue)
        let fraction = clamped - Double(lower)

        return cumulative[lower] + (cumulative[upper] - cumulative[lower]) * fraction
    }
    
}
