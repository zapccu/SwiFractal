//
//  ColorTableLCH.swift
//  SwiFractal
//
//  Created by Dirk Braner on 24.08.26.
//

import Foundation
import SwiftUI


//
// LCH coloring parameters
//
struct LCHParameters: FractalParameters {
    // Lightness parameters
    var lumMin: Double = 75.0           // Minimum brightness in range 0.0...100.0
    var lumRange: Double = 75.0         // Amplitude. Defines the contrast range. A smaller amplitude keeps
                                        // the image bright and reduces deep shadows
    var lumExponent: Double = 1.0       // <1: Luminance is increasing rapidly for small v values
                                        // >1: Luminance is increasing rapidly for high v values
                                        // Range 0.5...3.0
    
    // Chroma/saturation parameters
    var satBase: Double = 28.0          // Base saturation. If this parameter is set to 0.0, dark sections
                                        // will get grey / monochrome
    var satRange: Double = 75.0         // Controls the color intensity in range 1.0...120.0
    var satExponent: Double = 1.0       // <1: Saturation is increasing rapidly for small v values
                                        // >1: Saturation is increasing rapidly for high v values
                                        // Range 0.5...3.0

    // Hue parameters
    var hueStart: Double = 360.0        // Color circle scaling. Controls how fast a color circle is passed throught. Range 1.0...720.0
    var hueRange: Double = 1.0
    var hueExponent: Double = 1.5       // Compressing of color distribution. A value > 1.0 streches the color distribution
                                        // for low iteration counts and compresses it for high iteration counts. A value of 1.0
                                        // results in lineat color distribution
    
}

//
// LCH color table
//
struct ColorTableLCH : ColorTable {

    enum CodingKeys: String, CodingKey {
        case name, count, defColor, fixedSize, parameters
    }

    var name: String
    
    var count: Int = 0
    
    var fixedSize: Bool = true
    
    var cyclic: Bool {
        colors.count > 0 && colors.first == colors.last
    }
    
    /// LCH coloring parameters
    var parameters: LCHParameters
    
    /// Color array
    var colors: [RGBAColor] = []
    
    /// Default color
    var defColor: RGBAColor = .black
    
    /// Return gradient colors
    var gradient: [Color] {
        return stride(from: 0, to: colors.count, by: 2).map { colors[$0].color }
    }
    
    /// Init a LCH color table
    /// - Parameters:
    ///   - name: Name of color table
    ///   - parameters: LCH coloring parameters
    ///   - colorCount: Number of colors
    ///   - defColor: Default color
    init (_ name: String, parameters: LCHParameters, colorCount: Int, defColor: RGBAColor, fixedSize: Bool = true) {
        self.name = name
        self.parameters = parameters
        self.defColor = defColor
        self.fixedSize = fixedSize

        self.count = self.resize(colorCount: colorCount)
    }
    
    /// Custom decoder
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
            
        let name = try container.decode(String.self, forKey: .name)
        let count = try container.decode(Int.self, forKey: .count)
        let defColor = try container.decode(RGBAColor.self, forKey: .defColor)
        let fixedSize = try container.decode(Bool.self, forKey: .fixedSize)
        let parameters = try container.decode(LCHParameters.self, forKey: .parameters)

        self.init(name, parameters: parameters, colorCount: count, defColor: defColor, fixedSize: fixedSize)
    }
    
    /// Clone color table
    /// - Parameter colorCount: Number of colors in table
    /// - Returns: New color table
    func clone(colorCount: Int = 0) -> ColorTableLCH {
        .init(self.name, parameters: self.parameters, colorCount: colorCount == 0 ? self.count : colorCount,
              defColor: self.defColor, fixedSize: self.fixedSize)
    }
    
    /// Resize color table
    /// - Parameter colorCount: Number of colors
    /// - Returns: Number of colors (could differ from specified number)
    mutating func resize(colorCount: Int) -> Int {
        let numColors = max(colorCount, 2)

        colors = Array(repeating: .black, count: numColors)
        for i in 0..<numColors {
            let di = Double(i) / Double(numColors - 1)
            
            let sinPiDi = sin(Double.pi * di)
            let v = sinPiDi * sinPiDi
            
            // Calculate lightness
            let lProgress = pow(v, parameters.lumExponent)
            let lightness = Float(parameters.lumMin + (parameters.lumRange * lProgress))
                    
            // Calculate chroma / saturation
            let cProgress = pow(1.0 - v, parameters.satExponent)
            let chroma = Float(parameters.satBase + (parameters.satRange * cProgress))
                    
            // Calculate hue
            let hProgress = pow(di, parameters.hueExponent)
            let rawHue = parameters.hueStart + (parameters.hueRange * hProgress)
            let hue = Float(rawHue.truncatingRemainder(dividingBy: 360.0))
            
            colors[i] = RGBAColor(lch: (
                lightness: lightness.clamped(to: 0...100.0), chroma: max(chroma, 0.0), hue: hue < 0.0 ? hue + 360.0 : hue)
            )
        }
        
        return numColors
    }

}

