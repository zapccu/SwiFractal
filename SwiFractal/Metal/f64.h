//
//  f64.h
//
//  Part of Metal64
//
//  Implementation of datatype f64
//
//  Mandatory Xcode build settings:
//
//    Metal Compiler - Build Options - Math Mode = "Safe"
//    User Defined - MTL_FAST_MATH = "NO"
//
//  Created by Dirk Braner on 15.12.24.
//

#ifndef __F64_H
#define __F64_H

#include "f64fnc.h"

using namespace metal;


/// Struct for 64 bit floating points
struct f64 {
    float2 v;   /// A 64 bit floating point value is internally stored as float2
    
    /// Construct f64 with value 0
    f64() {
        v = float2(0.0f, 0.0f);
    }
    
    /// Construct f64 from float
    f64(float a) {
        v = float2(a, 0.0f);
    }
    
    /// Construct f64 from float2
    f64(float2 a) {
        v = a;
    }
    
    /// Construct f64 from 2 floats
    f64(float a, float b) {
        v = float2(a, b);
    }
    
    /// Assign float to f64
    f64 operator = (float a) {
        v = float2(a, 0.0f);
        return *this;
    }
    
    /// Check if zero
    bool isZero() {
        return all(v == 0.0);
    }
};


// Constants

constant f64 pi_f64   = f64(3.1415927, -8.742278e-08);      // PI
constant f64 pi2_f64  = f64(1.5707964, -4.371139e-08);      // PI / 2
constant f64 log2_f64 = f64(0.6931472, -1.9046542e-09);     // LOG(2)


// Arithmetic functions

f64 sqrt(f64);
f64 exp(f64);
f64 log(f64);
f64 pow(f64, f64);
f64 pow(f64, int);
f64 sin(f64);
f64 cos(f64);
f64 tan(f64);
f64 asin(f64);
f64 acos(f64);
f64 atan(f64);
f64 atan2(f64, f64);
f64 sinh(f64);
f64 cosh(f64);
f64 tanh(f64);


// Operators

f64 operator - (f64);
f64 operator + (f64, f64);
f64 operator + (f64, float);
f64 operator + (float, f64);
f64 operator - (f64, f64);
f64 operator - (f64, float);
f64 operator - (float, f64);
f64 operator * (f64, f64);
f64 operator * (f64, float);
f64 operator * (float, f64);
f64 operator / (f64, f64);
f64 operator / (f64, float);
f64 operator / (float, f64);
f64 operator % (f64, f64);
f64 operator % (f64, float);
f64 operator % (float, f64);

bool operator == (f64, f64);
bool operator != (f64, f64);
bool operator < (f64, f64);
bool operator > (f64, f64);
bool operator <= (f64, f64);
bool operator >= (f64, f64);


// Conversion and testing functions

bool isZero(f64);
int32_t toInt32(f64);
float toFloat(f64);

#endif

