
//
//  mandelbrot.metal
//
//

#include <metal_stdlib>
#include <c64.h>
#include "mandelbrot.h"

using namespace metal;

int findOrbit2(thread c64 *orbits, c64 Z, int orbitIndex, int orbitsEntries, f64 tolerance) {
    for(int i=orbitIndex-1; i>=0; i--) {
        c64 diff = orbits[i] - Z;
        if (norm(diff) < tolerance) {
            return i;
        }
    }
    return -1;
}

// Find orbit
// - Parameters:
//   - orbits: Array with Z values
//   - Z: Current Z value
//   - orbitIndex: Current orbits index
//   - orbitEntries: Number of elements in orbit array
//   - tolerance: Tolerance
// - Returns: Orbit index of first matching Z or -1 if no orbit found
int findOrbit(thread c64 *orbits, c64 Z, int orbitIndex, int orbitEntries, f64 tolerance) {
    for(int n=1; n<=orbitEntries; n++) {
        int i = orbitIndex - n;
        if (i < 0) { i += orbitEntries; }
        c64 diff = orbits[i] - Z;
        if (norm(diff) < tolerance) { return orbitEntries - n; }
    }
    return -1;
}

// Calculate normal.
// - Parameters:
//   - Z: Z value
//   - D: Derivation of Z
// - Returns: Normal as c64 value
c64 inline normalize(c64 Z, c64 D) {
    c64 u = Z / D;
    f64 len = abs(u);
    return len > 0.0 ? (u / len) : c64(0.0);
}

// Mandelbrot iteration
// - Parameters:
//   - C: Complex point
//   - J: Julia point
//   - MP: Compute parameters
// - Returns: Mandelbrot result
MandelbrotResult iterateMandel(c64 C, constant MetalComputeParameters *MP) {

    f64 stripeAvg = 0.0;        // Stripe average value
    f64 stripet = 0.0;          // Current stripe value

    c64 Z = 0;                  // Start of iteration: Z = Julia point
    c64 D = 0.0;                // 1st derivation of Z: D = 1
    c64 Z1 = c64(10.0, 10.0);   // Old Z for fast orbit detection
    f64 nZ = 0.0;               // Squared norm of Z

    int period = 0;             // Period counter for fast orbit detection

    c64 orbits[100];            // Orbit values
    orbits[0] = Z;
    int orbitIndex = 1;         // Index of next orbit entry
    int orbitEntries = 1;       // Number of entries in the orbit buffer
    int orbitLength = 20;
    
    // Convert Float2 values to f64
    f64 logPixel = f64(MP->logPixel);
    f64 invDistThreshold = f64(MP->invDistThreshold);
    f64 logBailout = f64(MP->logBailout);
    f64 stripes = f64(MP->stripes);
    f64 stripeSig = f64(MP->stripeSig);

    float dExp = 0.0f;              // Exponent of D. D' = D * 2^dExp
    const float DLIM = 0x1p60f;     // |D| < 2^60 → norm(D) < 2^120, no overflow
    
    int i;

    for(i=0; i<=MP->iterations; i++) {
        // Derivation D of Z
        // D = (Z + Z) * D + 1.0;
        D = (Z + Z) * D + f64(exp2(-dExp));   // +1 in scaled system; becomes 0 with very large dExp
        float dm = max(abs(D.real().v.x), abs(D.imaginary().v.x));
        if (dm > DLIM) {
            D = scale2(D, 0x1p-60f);
            dExp += 60.0f;
        }
        
        // Iteration formula
        Z = sqr(Z) + C;
        
        if (MP->bStripes) {
            stripet = (sin(stripes * atan2(Z.imaginary(), Z.real())) + 1.0) * 0.5;
        }
        
        nZ = norm(Z);
        
        if (flt(nZ) > MP->bailout) {
            f64 logAbsZ = log(nZ) * 0.5;
            
            // Calculate smooth iteration value for smooth coloring
            //
            // This value must be added to the iteration count.
            // logRatio = 2 * log(aZ) / log(bailout)
            // smoothIter = -log(logRatio) * _NC.RLOG2
            f64 smoothIter = -log(logAbsZ / logBailout) * F64_1_LOG2;
      
            // Normalize, exterior distance, filaments
            f64 dLength = abs(D);
            f64 logPixelDist = f64(FLT_MAX);
            f64 filamentStrength = 0.0;
            c64 normal = 0.0;
            if (dLength > 0.0) {
                // Normalize
                normal = normalize(Z, D);
                
                // Calculate exterior distance
                // distance = (absZ * logAbsZ * 2) / |D|, calculated in RT to avoid over-/underflow
                // - Logarithm must be calculated with arbitrary precision
                // - MandelbrotResult supports only Double values
                // - We need the logarithm of the distance for color mapping
                f64 logAbsD = log(dLength) + f64(dExp) * F64_LOG2;    // log|D_wahr|
                // log(distance) = log(|Z| * log|Z| * 2) - log|D|
                f64 logDist = log(sqrt(nZ) * logAbsZ * 2.0) - logAbsD;
                logPixelDist = logDist - logPixel;

                // Calculate filament: dimensionless ratio in RT, the rest in Double
                // ratio = distance * invDistThreshold, in Log space (underflow protection)
                f64 logRatio = logDist + log(invDistThreshold);
                f64 ratio = (flt(logRatio) < -80.0f) ? f64(0.0) : exp(logRatio);
                f64 t = min(max(1.5 - ratio, 0.0), 1.0);
                filamentStrength = t * t * (3.0 - 2.0 * t);
            }

            // Calculate stripes
            if (MP->bStripes) {
                f64 frac = max(min(smoothIter, 1.0), 0.0);

                // Exponential moving average
                // stripeAvg = stripeAvg * (1.0 + smoothIter * (P.MP.stripeSig - 1.0))
                //             + stripet * smoothIter * (1.0 - P.MP.stripeSig)
                stripeAvg = (stripeAvg * (1.0 + frac * (stripeSig-1.0)) + stripet * frac * (1.0 - stripeSig));

                // BIAS correction
                // stripeAvg = stripeAvg /
                //             (1 - pow(P.colorParameters.stripeSig, Double(i))
                //             * (1 + smoothIter * (P.colorParameters.stripeSig - 1)))
                stripeAvg = stripeAvg / (1.0 - pow(stripeSig, i) * (1.0 + frac * (stripeSig - 1.0)));
            }

            smoothIter += float(i);
            
            // Check for Inf values in the results.
            // If any of the values are not finite, return flag = R_ERROR (red color on CPU side)
            if (!isfinite(nZ.v.x) || !isfinite(dLength.v.x) || !isfinite(normal.real().v.x)) {
                return { smoothIter.v, F2_ZERO, F2_ZERO, F2_ZERO, F2_ZERO, F2_ZERO, F2_ZERO, R_ERROR };
            }
            
            return {
                smoothIter.v,                           // smoothIter
                nZ.v,                                   // norm of last Z
                normal.real().v, normal.imaginary().v,  // normal.real, normal imaginary
                logPixelDist.v,                         // logarithm of distance
                stripeAvg.v,                            // stripe average value
                filamentStrength.v,                     // filament
                R_BAILOUT                               // flag
            };
        }
        
        if (MP->colorizeInside == CI_ORBITS) {
            // Long periodicity check
            int index = findOrbit(orbits, Z, orbitIndex, orbitEntries, f64(1.0e-24));
            if (index > -1) {
                index = findOrbit(orbits, Z, orbitIndex, orbitEntries, f64(1.0e-22));
                return {
                    flt2(i),                    // smoothIter
                    nZ.v,                       // norm of last Z
                    F2_ZERO, F2_ZERO,           // normal.real, normal.imaginary
                    flt2(orbitEntries - index), // distance = orbit length
                    F2_ZERO,                    // stripeAvg
                    F2_ZERO,                    // filament
                    R_INSIDE                    // flag
                };
            }
            orbits[orbitIndex++] = Z;
            orbitEntries = min(orbitEntries + 1, orbitLength);
            if (orbitIndex == orbitLength) { orbitIndex = 0; }
        }
        else if (MP->colorizeInside == CI_FAST_ORBITS) {
            // Simplified periodicity check, no orbit colorization
            c64 diff = Z - Z1;
            if (norm(diff) < 1.0e-10) {
                return {
                    flt2(i),                // smoothIter
                    nZ.v,                   // norm of last Z
                    F2_ZERO, F2_ZERO,       // normal.real, normal.imaginary
                    flt2(period),           // distance = orbit period
                    F2_ZERO,                // stripeAvg
                    F2_ZERO,                // filament
                    R_INSIDE                // flag
                };
            }
            
            period++;
            if (period > 20) {
                period = 0;
                Z1 = Z;
            }
        }
        
        if (MP->bStripes) {
            // Calculate exponential moving average of stripe value
            // stripeAvg = expMovAvg(previousAvg: stripeAvg, smooth: P.MP.stripeSig, newValue: stripet)
            stripeAvg = stripeAvg * stripeSig + stripet * (1 - stripeSig);
        }

    }
    
    return {
        flt2(i),            // smoothIter
        F2_ZERO,            // norm of last Z
        F2_ZERO, F2_ZERO,   // normal.real, normal.imag
        F2_ZERO,            // distance
        F2_ZERO,            // stripeAvg
        F2_ZERO,            // filament
        R_MAX_ITERATIONS    // flag
    };
}

// Kernel function for Mandelbrot calculation
// - Parameters:
//   - C: Array with complex coordinates
//   - MP: Compute parameters
//   - resultArray: Array with calculation results
kernel void mandelbrot(device const float4 *C,
                       constant MetalComputeParameters *MP,
                       device MandelbrotResult *resultArray,
                       uint   index [[ thread_position_in_grid ]])
{
    // Result array contains a MandelbrotResultMtl element for each point in array C
    resultArray[index] = iterateMandel(c64(C[index]), MP);
}


