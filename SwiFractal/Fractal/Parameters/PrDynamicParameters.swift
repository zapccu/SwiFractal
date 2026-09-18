//
//  PrDynamicParameters.swift
//  SwiFractal
//
//  Created by Dirk Braner on 25.03.26.
//

import Foundation
import SwiftUI


//
// Protocol for dynamic calculation fractalParameters
//
// Dynamic calculation fractalParameters are calculated / created based
// on fractal fractalParameters
//
protocol PrDynamicParameters<Parameters> : Sendable {
        
    // Any dynamic fractalParameters type must define a typealias 'ResultType' for
    // a fractal type specific calculation result
    //associatedtype ResultType: CalculationResult
    associatedtype Parameters: FractalData
    
    var fractalParameters: Parameters { get }
    
    // Final image resolution (no oversampling)
    var resolution: CGSize { get }
    var imageWidth:  Int { get }
    var imageHeight: Int { get }
    
    // Image resolution considering oversampling
    var osImageWidth: Int { get }
    var osImageHeight: Int { get }
    var osSize: ISize { get }

    // Limit values for calculation
    var limits: FractalLimits { get }
    
    // Color table
    //var colorTable: EnumColorTable { get set }
    
    // Lighning
    var lightning: Lightning { get }
    
}

extension PrDynamicParameters {
    
    var dimensions: FractalDimensions<Parameters.RT> { fractalParameters.dimensions }
    
    var imageWidth:  Int { Int(resolution.width) }
    
    var imageHeight: Int { Int(resolution.height) }
    
    var osImageWidth: Int { imageWidth * dimensions.oversampling }
    
    var osImageHeight: Int { imageHeight * dimensions.oversampling }

    var osSize: ISize {
        ISize(width: imageWidth * dimensions.oversampling, height: imageHeight * dimensions.oversampling)
    }
    
    var limits: FractalLimits { fractalParameters.limits }
    
    var colorParameters: FractalColorParameters { fractalParameters.colorParameters }

    var lightning: Lightning { Lightning(fractalParameters.lightParameters) }
}
