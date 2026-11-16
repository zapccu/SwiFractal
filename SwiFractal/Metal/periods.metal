
//
// Extend FractalCalculation by orbit detection and period detection
//
// Structure:
//   1. Detectors (OrbitBuffer, BrentState) deliver a period candidate
//   2. verifyCycle() checks the divisors of the candidate with Newton (refineCycle)
//      and accepts only attracting cycles near Z
//   3. insideResult() builds the MandelbrotResult depending on colorizeInside
//   4. findCycleAfterIteration() is the fallback for points not detected
//      until the iteration limit (slow convergence near the boundary)
//
//

#include <metal_stdlib>
#include <c64.h>
#include "mandelbrot.h"

using namespace metal;

