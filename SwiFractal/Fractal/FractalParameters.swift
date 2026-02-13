//
//  FractalParameters.swift
//  SwiFractal
//
//  Created by Dirk Braner on 13.02.26.
//

import Foundation


//
// Class for common fractal calculation parameters
//
class FractalParameters {
    var corner: Cplx
    var size: Cplx
    var diag: Double
    var lightning: Lightning
    var oversampling: Int = 1
    
    /// Initialize calculation parameter object
    ///
    /// Parameters:
    ///
    /// parameterset: Parameterset of child classes
    ///
    init(_ parameterset: ParameterSet = ParameterSet()) {
        let light: ParameterSet = parameterset["lightning", default: ParameterSet()]
        corner       = parameterset["corner", default: Cplx(-2.25,-1.5)]
        size         = parameterset["size", default: Cplx(3,3)]
        diag         = size.length
        lightning    = Lightning(light)
        oversampling = parameterset["oversampling", default: Int(1)]
    }
}
