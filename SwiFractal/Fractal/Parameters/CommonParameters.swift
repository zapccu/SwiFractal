//
//  CommonParameters.swift
//  SwiFractal
//
//  Created by Dirk Braner on 22.03.26.
//

import SwiftUI

struct CommonParameters : FractalParameters {
    
    // Default values
    static let defaultValues: [String : Any] = [
        "cornerX":      "-2.25",
        "cornerY":      "-1.5",
        "sizeX":        "3.0",
        "sizeY":        "3.0",
        "oversampling": 1 as Int,
        "lightning":    LightningParameters.defaultValues
    ]
    
    static let defaultSize: Double = 3.0
    
    var cornerX: String = "-2.25"         // Coordinate of left corner
    var cornerY: String = "-1.5"        // Coordinate of lower corner
    
    var sizeX: String = "3.0"           // Horizontal size
    var sizeY: String = "3.0"          // Vertical size

    var oversampling: Int = 1       // Oversampling. Range 1-3
    
    var lightning: LightningParameters = LightningParameters()   // Lightning parameters

    var nCornerX: Double { Double(cornerX) ?? -2.25 }
    var nCornerY: Double { Double(cornerY) ?? -1.5 }
    var nSizeX: Double  { Double(sizeX) ?? 3.0 }
    var nSizeY: Double  { Double(sizeY) ?? 3.0 }
}
