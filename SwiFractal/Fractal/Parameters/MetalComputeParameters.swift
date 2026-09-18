//
//  MandelbrotComputeParameters.swift
//  SwiFractal
//
//  Created by Dirk Braner on 21.03.26.
//

import Foundation
import Metal64

///
/// Parameter structure to be passed to Metal kernel function
///
struct MetalComputeParameters: MetalData {
    var iterations: Int32
    var bStripes: Int32
    var bailout: Float
    var logBailout: Float2
    var div_2_logBailout: Float2
    var stripes: Float2
    var stripeSig: Float2
    var steps: Float2
    var diag: Float2
    var distThreshold: Float2
}
