//
//  FractalParameters.swift
//  SwiFractal
//
//  Created by Dirk Braner on 24.03.26.
//

import Foundation
import SwiftMPx


///
/// Protocol for Fractal Data properties
/// Make fractal parameter properties conform to Codable and Equatable
///
protocol FractalParameters : Codable, Equatable {
    
}

///
/// Protocol for fractal parameters depending on precision
///
protocol FractalPrecisionParameters : FractalParameters {
    associatedtype MPFloatVersion: FractalParameters = Self

    func toMPFloat(precision: Int) -> MPFloatVersion
}

