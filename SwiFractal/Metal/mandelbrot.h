//
//  mandelbrot.h
//  SwiFractal
//
//  Headerfile for Metal kernel
//
//  Created by Dirk Braner on 03.01.25.
//

#ifndef __MANDELBROT_H
#define __MANDELBROT_H


/// Iteration parameters
/// This struct must match exactly with the Swift struct MetalComputeParameters
struct MetalComputeParameters {
    int32_t iterations;
    int32_t bStripes;
    float bailout;
    float2 logBailout;
    float2 div_2_logBailout;
    float2 stripes;
    float2 stripeSig;
    float2 diag;
    float2 distThreshold;
};

/// Result flags
/// Must match exactly with Swift struct MandelbrotResultFlags
#define R_CALCULATE 1
#define R_DEFAULT_COLOR 2
#define R_MAX_ITERATIONS 4
#define R_BAILOUT 8
#define R_INSIDE 16
#define R_ERROR 32
#define R_ALLCASES (R_DEFAULT_COLOR | R_MAX_ITERATIONS | R_BAILOUT | R_INSIDE | R_ERROR)

/// Iteration results
/// This struct must match exactly with the Swift struct MandelbrotResultMtl
struct MandelbrotResult {
    float2 smoothIter;
    float2 nZ;
    float2 normalReal;
    float2 normalImag;
    float2 distance;
    float2 potential;
    float2 stripeAvg;
    float2 filament;
    int32_t flags;
};


#endif

