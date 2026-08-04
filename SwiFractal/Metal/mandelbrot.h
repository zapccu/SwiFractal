//
//  mandelbrot.h
//  SwiFractal
//
//  Created by Dirk Braner on 03.01.25.
//

#ifndef __MANDELBROT_H
#define __MANDELBROT_H

#define CM_ITERATIONS 0
#define CM_DISTANCE   1
#define CM_POTENTIAL  2

#define PM_LINEAR 0
#define PM_MODULO 1
#define PM_HUE    2
#define PM_HUEDYN 3
#define PM_LCHDYN 4

// Color
/*
struct RGBAColor {
    float red = 0.0;
    float green = 0.0;
    float blue = 0.0;
    float alpha = 1.0;
};

RGBAColor operator * (RGBAColor c, float a) {
    RGBAColor n;
    n.red = c.red * a;
    n.green = c.green * a;
    n.blue = c.blue * a;
    n.alpha = 1.0;
    return n;
}
*/

// Iteration parameters
struct MandelbrotComputeParameters {
    int32_t iterations;
    int32_t colors;
    int32_t bDist;
    int32_t bShading;
    int32_t bStripes;
    int32_t bPotential;
    int32_t colorizeMode;
    int32_t paletteMode;
    int32_t ncycle;
    float2 bailout;
    float2 stripes;
    float2 stripeSig;
    float2 steps;
    float2 diag;
};

#define R_DEFAULT_COLOR 0
#define R_MAX_ITERATIONS 1
#define R_BAILOUT 2
#define R_INSIDE 4

// Iteration results
struct MandelbrotResult {
    float2 smoothIter;
    float2 nZ;
    float2 normalReal;
    float2 normalImag;
    float2 distance;
    float2 potential;
    float2 stripeAvg;
    int flags;
};


#endif

