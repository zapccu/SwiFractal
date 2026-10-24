
//
//  mandelbrot.metal
//
//

#include <metal_stdlib>
#include <c64.h>
#include "mandelbrot.h"

using namespace metal;

// Cubic Hermite interpolation
f64 interpolateCubic(f64 edge0, f64 edge1, f64 x) {
    // map x into [0, 1]
    // If x < edge0: t = 0; if x > edge1: t = 1
    f64 t = min(max((x - edge0) / (edge1 - edge0), f64(0.0)), f64(1.0));
    
    // Cubic Hermite interpolation
    t = t * t * (3.0 - 2.0 * t);
    
    // Return
    return max(min(t, 1.0), 0.0);
}

// Mandelbrot iteration
MandelbrotResult iterate(c64 C, device const MetalComputeParameters *MP, device const float2 *Potentials) {
    
    f64 distance = 0.0;      // Distance of current point to Mandelbrot set
    f64 logPixelDist = 0.0;  // Logarithm of distance
    f64 potential = 0.0;     // Potential of current point
    f64 stripeAvg = 0.0;     // Stripe average value
    f64 stripet = 0.0;       // Current stripe value

    f64 logPixel = f64(MP->logPixel);
    f64 logBailout = f64(MP->logBailout);
    f64 stripes = f64(MP->stripes);
    f64 stripeSig = f64(MP->stripeSig);

    c64 Z = 0.0;             // Start of iteration: Z = 0
    f64 nZ = 0.0;            // Squared norm of Z: Z.imaginary * Z.imaginary + Z.real * Z.real
    f64 nZ1 = 10.0;          // Old value of nZ for fast orbit detection
    f64 absZ = 0.0;          // abs(Z) = sqrt(nZ)
    f64 logAbsZ = 0.0;
    f64 logZn;
    c64 normal;

    int period = 0;          // Period counter for fast orbit detection
    c64 D = 0.0;             // 1st derivation of Z: D = 0
    f64 smoothIter = 0.0;    // Smooth iteration counter
    f64 invDistThreshold = f64(MP->invDistThreshold);
    f64 filament = 0.0;
    int i;

    for(i=0; i<=MP->iterations; i++) {
        
        // Iteration formula
        Z = sqr(Z) + C;
        
        if (MP->bStripes) {
            stripet = (sin(stripes * atan2(Z.imaginary(), Z.real())) + 1.0) * 0.5;
        }
        
        nZ = norm(Z);
        
        if (nZ.v.x > MP->bailout) {
            absZ = sqrt(nZ);
            logAbsZ = log(absZ);
            
            // Calculate smoothiter
            smoothIter = -log(logAbsZ / logBailout) * F64_1_LOG2;
            
            // Distance calculation
            distance = absZ * logAbsZ * 2.0 / norm(D);
            logPixelDist = log(distance) - logPixel;
            
            // Filament calculation
            f64 ratio = distance * invDistThreshold;
            f64 t = min(max(1.5 - ratio, 0.0), 1.0);     // 1 for ratio <= 0.5, 0 for ratio >= 1.5
            f64 filamentStrength = t * t * (3.0 - 2.0 * t);
            
            // Potential calculation
            potential = logAbsZ * f64(Potentials[i]);

            if (MP->bStripes) {
                // Stripes calculation
                stripeAvg = (stripeAvg * (1.0 + smoothIter * (stripeSig-1.0)) + stripet * smoothIter * (1.0 - stripeSig));
                stripeAvg = stripeAvg / (1.0 - pow(stripeSig, f64(i)) * (1.0 + smoothIter * (stripeSig - 1.0)));
            }
            

            smoothIter += i;
            normal = Z / D;
            
            return {
                smoothIter.v,
                nZ.v,
                normal.real().v, normal.imaginary().v,
                distance.v,
                potential.v,
                stripeAvg.v,
                filamentStrength.v,
                R_BAILOUT
            };
        }
        
        // Simplified periodicity check, no orbit colorization
        if (abs(nZ.v.x - nZ1.v.x) < 1.0e-10) {
            return { smoothIter.v, nZ.v, normal.real().v, normal.imaginary().v, distance.v, potential.v, stripeAvg.v, filament.v, R_MAX_ITERATIONS };
        }
        else {
            period++;
            if (period > 20) {
                period = 0;
                nZ1 = nZ;
            }
        }
        
        D = (Z + Z) * D + 1.0;
    }
    
    return { smoothIter.v, nZ.v, normal.real().v, normal.imaginary().v, distance.v, potential.v, stripeAvg.v, filament.v, R_MAX_ITERATIONS };
}


// Kernel function for Mandelbrot calculation
kernel void mandelbrot(device const float4 *C,                          // Array with complex coordinates
                       device const MetalComputeParameters *MP,         // Compute parameters
                       device const float2 *Potentials,                 // Potential factors
                       device MandelbrotResult *resultArray,            // Calculation results
                       uint   index [[ thread_position_in_grid ]])
{
    // Result array contains a MandelbrotResultMtl element for each point in array C
    resultArray[index] = iterate(c64(C[index]), MP, Potentials);
}


