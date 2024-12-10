//
//  ColorTable.swift
//  SwiFractal
//
//  Created by Dirk Braner on 19.11.24.
//

struct ColorTable {
    
    // Predefined color tables
    static let greyScale = ColorTable(colorPoints: [RGBAColor(0.4, 0.4, 0.4), .white], 256)
    
    // Color array
    var colors: [RGBAColor]
    
    // Default color
    var defColor: RGBAColor = RGBAColor()
    
    // Return number of colors in table
    var count: Int { colors.count }
    
    // Init with color array
    init (colors: [RGBAColor], _ defColor: RGBAColor = RGBAColor()) {
        self.colors = colors
        self.defColor = defColor
    }
    
    // Init with unique color
    init (color: RGBAColor, _ count: Int = 1, _ defColor: RGBAColor = RGBAColor()) {
        colors = Array(repeating: color, count: count)
        self.defColor = defColor
    }

    init (colorPoints: [RGBAColor] = [.black, .white], _ count: Int = 2, _ defColor: RGBAColor = RGBAColor()) {
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
    
    subscript (_ index: Int) -> RGBAColor {
        guard index >= 0, index < colors.count else { return defColor }
        return colors[index]
    }
}

