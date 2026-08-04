//
//  Dimensions.swift
//  SwiFractal
//
//  Created by Dirk Braner on 14.07.26.
//

import Foundation
import SwiftMPx

struct MandelbrotDimensions<RT: PreciseFloatingPoint>: FractalParameters {
    var cornerX: String
    var cornerY: String
    var sizeX: String
    var sizeY: String
    
    var rtCornerX: RT { RT(cornerX) }
}
