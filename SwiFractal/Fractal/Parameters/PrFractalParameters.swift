//
//  FractalParameters.swift
//  SwiFractal
//
//  Created by Dirk Braner on 24.03.26.
//

import Foundation
import SwiftMPx


//
// Protocol for Fractal Data properties
// Make fractal parameter properties conform to Codable and Equatable
//
protocol FractalParameters : Codable, Equatable {
    
    //associatedtype MPFloatVersion: FractalParameters = Self
    
    // Convert structure conform to FractalParameters to Struct<MPFloat>
    //func toMPFloat(precision: Int) -> MPFloatVersion
    
}
/*
extension FractalParameters where MPFloatVersion == Self {
    func toMPFloat(precision: Int) -> Self { self }
}
*/

//
// Fractal parameters depending on precision
//
protocol FractalPrecisionParameters : FractalParameters {
    associatedtype MPFloatVersion: FractalParameters = Self

    func toMPFloat(precision: Int) -> MPFloatVersion
}

