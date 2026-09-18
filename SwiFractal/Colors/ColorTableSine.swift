//
//  ColorTableSine.swift
//  SwiFractal
//
//  Created by Dirk Braner on 17.08.26.
//

import Foundation
import SwiftUI


//
// Sine color table
//
struct ColorTableSine : ColorTable {

    enum CodingKeys: String, CodingKey {
        case name, count, defColor, fixedSize, thetas
    }

    var name: String = "Sine_85_0_15"
    
    var count: Int = 1
    
    var fixedSize: Bool = true
    
    var cyclic: Bool {
        colors.count > 0 && colors.first == colors.last
    }
    
    // Color array
    var colors: [RGBAColor] = [ .white ]
    
    // Default color
    var defColor: RGBAColor = .black
    
    var thetas: [Float] = [0.85, 0.0, 0.15]
    
    /// Return gradient colors
    var gradient: [Color] {
        return self.colors.map(\.color)
    }
    
    /// Init a sine color table
    /// - Parameters:
    ///   - name: Name of color table
    ///   - thetas: Array with 3 theta values in range 0-1
    ///   - colorCount: Number of colors
    ///   - defColor: Default color
    init (_ name: String, thetas: [Float], colorCount: Int, defColor: RGBAColor, fixedSize: Bool = true) {
        self.name = name
        self.thetas = thetas.count == 3 ? thetas : [0.85, 0.0, 0.15]
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
        let thetas = try container.decode([Float].self, forKey: .thetas)

        self.init(name, thetas: thetas, colorCount: count, defColor: defColor, fixedSize: fixedSize)
    }
    
    /// Clone color table
    /// - Parameter colorCount: Number of colors in table
    /// - Returns: New color table
    func clone(colorCount: Int = 0) -> ColorTableSine {
        .init(self.name, thetas: self.thetas, colorCount: colorCount == 0 ? self.count : colorCount,
              defColor: self.defColor, fixedSize: self.fixedSize)
    }
    
    /// Resize color table
    /// - Parameter colorCount: Number of colors
    /// - Returns: Number of colors (could differ from specified number)
    mutating func resize(colorCount: Int) -> Int {
        let numColors = max(colorCount, 2)
        let pi2 = 2 * Float.pi
        
        self.colors = RGBAColor.linspace(.black, .white, numColors)
        
        for i in 0..<numColors {
            colors[i].red   = 0.5 + 0.5 * sin((colors[i].red   + thetas[0]) * pi2)
            colors[i].green = 0.5 + 0.5 * sin((colors[i].green + thetas[1]) * pi2)
            colors[i].blue  = 0.5 + 0.5 * sin((colors[i].blue  + thetas[2]) * pi2)
        }
        
        return numColors
    }

}

