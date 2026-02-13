
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

/// Blending
float overlay(float x, float y, float gamma) {
    float out = 2.0 * y < 1.0 ? 2.0 * x * y : 1.0 - 2.0 * (1.0 - x) * (1.0 - y);
    
    return gamma == 1.0 ? out : out * gamma + x * (1 - gamma);
}

/// Blending of color value
float3 overlay(float3 x, float y, float gamma) {
    float3 out = y + y < 1.0 ? x * (y + y) : 1.0 - 2.0 * (1.0 - x) * (1.0 - y);
    return gamma == 1.0 ? out : out * gamma + x * (1 - gamma);
}

/// Shading
float3 shading(device const float4 *P, device const MandelbrotComputeParameters *MP,
                  float iterations, f64 distance, f64 stripeAvg, float brightness) {
    float pLen = float(MP->colors - 1);
    float bright = brightness;

    // Cycle through palette
    float nIter = fmod(sqrt(iterations), float(MP->ncycle)) / float(MP->ncycle);
    int palIndex = int(round(nIter * pLen));
    
    // Distance estimation: log transform and sigmoid on [0,1] => [0,1]
    f64 dist = -log(distance) / 12.0;
    dist = 1.0 / (1.0 + exp(-10.0 * ((2.0 * dist - 1.0) / 2.0)));
    
    // Shaders: steps and/or stripes
    float nshader = 0.0;
    float shader = 0.0;
    
    // Stripe shading
    if (stripeAvg > 0.0) {
        nshader = nshader + 1.0;
        shader = shader + toFloat(stripeAvg);
    }
    
    // Step shading
    if (MP->steps.x > 0) {
        // Color update: constant color on each major step
        float steps = 1.0/MP->steps.x;
        palIndex = int(round((nIter - fmod(nIter, steps)) * pLen));

        // Major step: step_s frequency
        float x = fmod(nIter, steps) / steps;
        float lightStep1 = 6.0 * (1.0 - pow(x, 5.0) - pow((1.0 - x), 100.0)) / 10.0;

        // Minor step: n for each major step
        steps /= 8;
        x = fmod(nIter, steps) / steps;
        float lightStep2 = 6.0 * (1.0 - pow(x, 5.0) - pow((1.0 - x), 30.0)) / 10.0;

        // Overlay merge between major and minor steps
        float lightStep = overlay(lightStep2, lightStep1, 1);
        nshader = nshader + 1.0;
        shader = shader + lightStep;
    }
    
    // Applying shaders to brightness
    if (nshader > 0) {
        bright = overlay(brightness, shader/nshader, 1) * toFloat((1.0 - dist) + dist * brightness);
    }
    
    return overlay(P[palIndex].xyz, bright, 1);
    // color.red = overlay(color.red, bright, 1);
    // color.green = overlay(color.green, bright, 1);
    // color.blue = overlay(color.blue, bright, 1);

    // return color;
}

/// Map color value
float4 mapColorValue(device const float4 *P, device const MandelbrotComputeParameters *MP,
                        float iterations, f64 nZ, c64 normal, f64 distance, f64 potential, f64 stripeAvg) {
    float pLen = float(MP->colors);
    float brightness = 1.0;
    // RGBAColor color;
    float4 color;
    
    /*
    if MP.colorMapping.colorizeOptions && .simple3d {
        let absNormal = normal / Cplx(normal.length)
        let vecNormal = Vector(absNormal.real, absNormal.imaginary, 1.0)
        brightness = MP.lightning.simple3D(vecNormal)
    }
    else if MP.colorMapping.colorizeOptions && .blinnPhong {
        let absNormal = normal / Cplx(normal.length)
        let vecNormal = Vector(absNormal.real, absNormal.imaginary, 1.0)
        brightness = MP.lightning.blinnPhong(vecNormal)
    }

    let fBrightness = Float(brightness)
    */

    if (stripeAvg > 0 || MP->steps.x > 0) {
        return float4(shading(P, MP, iterations, distance, stripeAvg, brightness), 1.0);
    }
    else if (MP->colorizeMode == CM_ITERATIONS) {
        if (MP->paletteMode == PM_LINEAR) {
            color = P[int(iterations/float(MP->iterations) * pLen)] * brightness;
        }
        else if (MP->paletteMode == PM_MODULO) {
            color = P[int(pLen * iterations/float(MP->iterations)) % MP->ncycle] * brightness;
        }
        /*
        else if (MP->paletteMode == PM_HUEDYN) {
            float h = float(int(pow((iterations) * 360, 1.5)) % 360);
            // For hsl model saturation must be set to 0.5
            color = RGBAColor(HSB(h/360.0, 1.0, brightness));
        }
         */
    }
    else if (MP->colorizeMode == CM_DISTANCE) {
        color = P[toInt32(tanh(distance) * pLen)] * brightness;
    }
    else if (MP->colorizeMode == CM_POTENTIAL) {
        color = P[int(pLen * iterations/float(MP->iterations))] * brightness;
    }

    color.a = 1.0;
    return color;
}

/// Mandelbrot iteration
float4 iterate(c64 C, device const float4 *P, device const MandelbrotComputeParameters *MP) {
    c64 Z;
    c64 D = 1.0;
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
        if (toFloat(nZ) > MP->bailout.x) {
            if (MP->bDist || MP->bStripes) {
                // Distance calculation
                aZ = sqrt(nZ);
                logaZ = log(aZ);
                logRatio = (logaZ + logaZ) / logBailout;
                smoothIter = 1.0 - log(logRatio) / log2_f64;
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
                potential = log(logZn / log2_f64) / log2_f64;
            }
            
            return mapColorValue(P, MP, float(i)+smoothIter.v.x, nZ, Z/D, distance/f64(MP->diag), potential, stripeAvg);
        }
        
        // Simplified periodicity check, no orbit colorization
        if (abs(nZ.v.x - nZ1.v.x) < 1.0e-10) {
            return float4(0, 0, 0, 1);
        }
        else {
            period++;
            if (period > 20) {
                period = 0;
                nZ1 = nZ;
            }
        }
    }
    
    return float4(0, 0, 0, 1);
}


/// Kernel function for Mandelbrot calculation
kernel void mandelbrot(device const float4 *C,                          // Array with complex coordinates
                       device const float4 *P,                          // Color palette
                       device const MandelbrotComputeParameters *MP,    // Compute parameters
                       device float4 *resultArray,                      // Calculation results
                       uint   index [[ thread_position_in_grid ]])
{
    // Result array contains a MandelbrotResult element for each point in array C
    resultArray[index] = iterate(c64(C[index]), P, MP);
}


