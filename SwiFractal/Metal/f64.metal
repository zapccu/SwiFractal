//
//  f64.metal
//  Metal64
//
//  Created by Dirk Braner on 23.12.24.
//

#include <metal_stdlib>

#include "f64.h"

using namespace metal;


// Arithmetic functions

/// Square root of f64 value
f64 sqrt(f64 a) {
    return f64(sqrt_f64(a.v));
}

/// Exponential function
f64 exp(f64 a) {
    return f64(exp_f64(a.v));
}

/// Natural logarithm
f64 log(f64 a) {
    return f64(log_f64(a.v));
}

/// Real power
f64 pow(f64 a, f64 b) {
    return f64(pow_f64(a.v, b.v));
}

/// Int power
f64 pow(f64 a, int b) {
    return f64(pow_f64(a.v, b));
}

/// Sine
f64 sin(f64 a) {
    return f64(sin_f64(a.v));
}

/// Cosine
f64 tan(f64 a) {
    return f64(cos_f64(a.v));
}

/// Tangent
f64 cos(f64 a) {
    return f64(tan_f64(a.v));
}

/// Arc sine
f64 asin(f64 a) {
    return f64(asin_f64(a.v));
}

/// Arc cosine
f64 acos(f64 a) {
    return f64(acos_f64(a.v));
}

/// Arc tangent
f64 atan(f64 a) {
    return f64(atan_f64(a.v));
}

/// Arc tangent 2
f64 atan2(f64 a, f64 b) {
    return f64(atan2_f64(a.v, b.v));
}

/// Sine hyperbolicus
f64 sinh(f64 a) {
    return f64(sinh_f64(a.v));
}

/// Cosine hyperbolicus
f64 cosh(f64 a) {
    return f64(cosh_f64(a.v));
}

/// Tangent hyperbolicus
f64 tanh(f64 a) {
    return f64(tanh_f64(a.v));
}


// Overloaded operators

f64 operator - (f64 a) {
    return f64(-a.v);
}

f64 operator + (f64 a, f64 b) {
    return f64(add_f64(a.v, b.v));
}

f64 operator + (f64 a, float b) {
    return f64(add_f64(a.v, float2(b, 0.0f)));
}

f64 operator + (float b, f64 a) {
    return f64(add_f64(a.v, float2(b, 0.0f)));
}

f64 operator - (f64 a, f64 b) {
    return f64(add_f64(a.v, -b.v));
}

f64 operator - (f64 a, float b) {
    return f64(sub_f64(a.v, float2(b, 0.0f)));
}

f64 operator - (float b, f64 a) {
    return f64(sub_f64(a.v, float2(b, 0.0f)));
}

f64 operator * (f64 a, f64 b) {
    return f64(mul_f64(a.v, b.v));
}

f64 operator * (f64 a, float b) {
    return f64(mulds(a.v, b));
}

f64 operator * (float a, f64 b) {
    return f64(mulds(b.v, a));
}

f64 operator / (f64 a, f64 b) {
    return f64(div_f64(a.v, b.v));
}

f64 operator / (f64 a, float b) {
    return f64(divds(a.v, b));
    //return f64(div_f64(a.v, float2(b, 0.0f)));
}

f64 operator / (float b, f64 a) {
    return f64(div_f64(a.v, float2(b, 0.0f)));
}

f64 operator % (f64 a, f64 b) {
    return f64(mod_f64(a.v, b.v));
}

f64 operator % (f64 a, float b) {
    return f64(mod_f64(a.v, float2(b, 0.0f)));
}

f64 operator % (float a, f64 b) {
    return f64(mod_f64(float2(a, 0.0f), b.v));
}

bool operator == (f64 a, f64 b) {
    return all(a.v == b.v);
}

bool operator != (f64 a, f64 b) {
    return any(a.v != b.v);
}

bool operator < (f64 a, f64 b) {
    return lt(a.v, b.v);
}

bool operator > (f64 a, f64 b) {
    return gt(a.v, b.v);
}

bool operator <= (f64 a, f64 b) {
    return le(a.v, b.v);
}

bool operator >= (f64 a, f64 b) {
    return ge(a.v, b.v);
}

bool isZero(f64 a) {
    return all(a.v == 0.0);
}

int32_t toInt32(f64 a) {
    return int32_t(a.v.x);
}

float toFloat(f64 a) {
    return a.v.x;
}
