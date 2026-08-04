
//
//  mandelbrot.metal
//
//

#include <metal_stdlib>
#include "c64.h"
#include "mandelbrot.h"

using namespace metal;


// ==========================================================
//  Calculate Mandelbrot set, using classes c64 and f64
// ==========================================================

/// Mandelbrot iteration
MandelbrotResult iterate(c64 C, device const float4 *P, device const MandelbrotComputeParameters *MP) {
    c64 Z;
    c64 D = 1.0;
    c64 normal;
    f64 nZ = 0.0, aZ = 0.0, nZ1 = 10.0;
    f64 logRatio;
    f64 logZn;
    f64 logaZ;
    f64 stripet;
    f64 smoothIter = 0.0;
    f64 stripeAvg = 0.0;
    f64 distance = 0.0;
    f64 potential = 0.0;
    f64 logBailout = log(f64(MP->bailout));
    int i;
    int period = 0;
    
    for(i=0; i<=MP->iterations; i++) {
        if (MP->bDist || MP->bShading) {
            // 1st derivation of Z
            D = D * 2.0 * Z + 1.0;
        }
        
        Z = sqr(Z) + C;
        
        if (MP->bStripes) {
            stripet = (sin(f64(MP->stripes) * atan2(Z.imaginary(), Z.real())) + 1.0) / 2.0;
        }
        
        nZ = norm(Z);
        if (flt(nZ) > MP->bailout.x) {
            if (MP->bDist || MP->bStripes) {
                // Distance calculation
                aZ = sqrt(nZ);
                logaZ = log(aZ);
                logRatio = (logaZ + logaZ) / logBailout;
                smoothIter = 1.0 - log(logRatio) / F64_LOG2;
                distance = (aZ * logaZ / norm(D) * 0.5);
            }
            
            if (MP->bStripes) {
                // Stripes calculation
                stripeAvg = (stripeAvg * (1.0 + smoothIter * (f64(MP->stripeSig)-1.0)) + stripet * smoothIter * (1.0 - f64(MP->stripeSig)));
                stripeAvg = stripeAvg / (1.0 - pow(f64(MP->stripeSig), f64(i)) * (1.0 + smoothIter * (f64(MP->stripeSig) - 1.0)));
            }
            
            if (MP->bPotential) {
                // Potential calculation
                logZn = log(nZ) / 2.0;
                potential = log(logZn / F64_LOG2) / F64_LOG2;
            }

            normal = Z / D;
            return { smoothIter.v, nZ.v, normal.real().v, normal.imaginary().v, distance.v, potential.v, stripeAvg.v, R_BAILOUT };
        }
        
        // Simplified periodicity check, no orbit colorization
        if (abs(nZ.v.x - nZ1.v.x) < 1.0e-10) {
            return { smoothIter.v, nZ.v, normal.real().v, normal.imaginary().v, distance.v, potential.v, stripeAvg.v, R_MAX_ITERATIONS };
        }
        else {
            period++;
            if (period > 20) {
                period = 0;
                nZ1 = nZ;
            }
        }
    }
    
    return { smoothIter.v, nZ.v, normal.real().v, normal.imaginary().v, distance.v, potential.v, stripeAvg.v, R_MAX_ITERATIONS };
}


/// Kernel function for Mandelbrot calculation
kernel void mandelbrot(device const float4 *C,                          // Array with complex coordinates
                       device const float4 *P,                          // Color palette
                       device const MandelbrotComputeParameters *MP,    // Compute parameters
                       device MandelbrotResult *resultArray,                      // Calculation results
                       uint   index [[ thread_position_in_grid ]])
{
    // Result array contains a MandelbrotResult element for each point in array C
    resultArray[index] = iterate(c64(C[index]), P, MP);
}


