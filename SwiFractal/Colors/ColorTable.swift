//
//  ColorTable.swift
//  SwiFractal
//
//  Created by Dirk Braner on 19.11.24.
//

import Foundation

///
/// Color table
///
struct ColorTable {
    
    // Predefined color tables
    static let grey  = ColorTable(colorPoints: [RGBAColor(80.0/255.0, 80.0/255.0, 80.0/255.0), .white], count: 4096)
    static let sinus = ColorTable(thetas: RGBAColor(0.85, 0.0, 0.15), count: 4096)
    
    // Color array
    var colors: [RGBAColor]
    
    // Default color
    var defColor: RGBAColor = .black
    
    /// Return number of colors in table
    var count: Int { colors.count }
    
    /// Return color array converted to RGBA color values
    var rgbaColors: [RGBA] { colors.map { $0.rgba} }
    
    /// Init color table with color array
    init (colors: [RGBAColor], defColor: RGBAColor = .black) {
        self.colors = colors
        self.defColor = defColor
    }
    
    /// Init color table with unique color
    init (color: RGBAColor, count: Int = 1, defColor: RGBAColor = .black) {
        colors = Array(repeating: color, count: count)
        self.defColor = defColor
    }

    /// Init color table based on color points
    init (colorPoints: [RGBAColor], count: Int = 2, defColor: RGBAColor = .black) {
        if colorPoints.isEmpty {
            // Greyscale palette
            colors = linspace(.white, .black, max(count, 2))
        }
        else if colorPoints.count == 1 {
            // Monochrome palette
            colors = Array(repeating: colorPoints[0], count: max(count, 1))
        }
        else {
            let n = max(count, colorPoints.count)
            var secSize = Int(n / (colorPoints.count - 1))
            colors = []
            for i in 0..<(colorPoints.count - 1) {
                if secSize + colors.count - 1 > n {
                    secSize = n - colors.count
                }
                colors += linspace(colorPoints[i], colorPoints[i+1], secSize)
            }
        }

        self.defColor = defColor
    }
    
    /// Init a sine color table
    init (thetas: RGBAColor, count: Int = 2, defColor: RGBAColor = .black) {
        let numColors = max(count, 2)
        colors = linspace(.black, .white, numColors)
        for i in 0..<numColors {
            colors[i].red = 0.5 + 0.5 * sin((colors[i].red + thetas.red) * 2 * Float.pi)
        }
        
        self.defColor = defColor
    }
    
    /// Return color table entry at specified index or default color if index is out of range
    subscript (_ index: Int) -> RGBAColor {
        guard index >= 0, index < colors.count else { return defColor }
        return colors[index]
    }
}

