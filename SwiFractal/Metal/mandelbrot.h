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

// Colorize inside flags
// Must match exactly with Swift enum EnumColorizeInside
#define CI_DEFAULT_COLOR 0  // Inside of Mandelbrot set is set to default color
#define CI_ORBITS 1         // Colorize orbits inside Mandelbrot set using full orbit detection
#define CI_BRENT 2          // Brent's period detection
#define CI_BRENT_LAMBDA 3   // Brent's period detection with lambda color assignment
#define CI_FAST_ORBITS 4    // Use fast orbit detection without coloring the interior of Mandelbrot set
#define CI_DISTANCE 5       // Colorize distance inside Mandelbrot set, implies distance calculation

// Iteration parameters
// This struct must match exactly with the Swift struct MetalComputeParameters
struct MetalComputeParameters {
    int32_t iterations;         // Maximum number of iterations
    int32_t bStripes;           // True if stripes must be calculated
    int32_t colorizeInside;     // Colorize mode for interior of Mandelbrot set
    float bailout;              // Bailout radius
    float2 logBailout;          // log(bailout)
    float2 div_2_logBailout;    // 2 / log(bailout)
    float2 stripes;
    float2 stripeSig;
    float2 logPixel;
    float2 invDistThreshold;
};

// Result flags
// Must match exactly with Swift struct MandelbrotResultFlags
#define R_CALCULATE 1
#define R_DEFAULT_COLOR 2
#define R_MAX_ITERATIONS 4
#define R_BAILOUT 8
#define R_INSIDE 16
#define R_ERROR 32
#define R_ALLCASES (R_DEFAULT_COLOR | R_MAX_ITERATIONS | R_BAILOUT | R_INSIDE | R_ERROR)

// Iteration results
// This struct must match exactly with the Swift struct MandelbrotResultMtl
struct MandelbrotResult {
    float2 smoothIter;
    float2 nZ;
    float2 normalReal;
    float2 normalImag;
    float2 distance;
    float2 stripeAvg;
    float2 filament;
    int32_t flags;
};

c64 normalize(c64 Z, c64 D);
int findOrbit(thread c64 *orbits, c64 Z, int orbitIndex, int orbitEntries, f64 tolerance);
int findOrbit2(thread c64 *orbits, c64 Z, int orbitIndex, int orbitsEntries, f64 tolerance);

// Exact scaling of a f64 value with 2^k. Implemented in mandelbrot.metal.
f64 inline scale2(f64 a, float s) { return f64(float2(a.v.x * s, a.v.y * s)); }
c64 inline scale2(c64 a, float s) { return c64(scale2(a.real(), s), scale2(a.imaginary(), s)); }


#endif

