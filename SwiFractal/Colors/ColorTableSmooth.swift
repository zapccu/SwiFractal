//
//  ColorTableSmooth.swift
//  SwiFractal
//
//  Created by Dirk Braner on 17.08.26.
//

import Foundation
import SwiftUI


///
/// Smooth color table.
/// Default is a table with 1 white color entry.
/// If color table has more than 1 color points, color entries will be interpolated
/// between color points.
/// A cyclic color table must have 1 or more than 2 color points and first and last color
/// point must be identical
///
struct ColorTableSmooth: ColorTable {
    
    // Do not encode/decode the color array
    enum CodingKeys: String, CodingKey {
        case name, count, defColor, fixedSize, colorPoints
    }
    
    // Color table name
    var name: String = "MonoWhite"
    
    // Color array
    var colors: [RGBAColor] = [.white]
    
    // Default color
    var defColor: RGBAColor = .black
    
    /// Return number of colors in table
    var count: Int = 1
    
    /// Color table has fixed size
    var fixedSize: Bool = true
    
    /// Color table is cyclic
    var cyclic: Bool {
        self.colorPoints.count == 1 || (self.colorPoints.count > 2 && self.colorPoints.first != self.colorPoints.last)
    }
    
    // Fixed color points
    var colorPoints: [RGBAColor] = [.white]
    
    /// Return gradient colors
    var gradient: [Color] {
        return self.colorPoints.map(\.color)
    }

    /// Init color table based on color points
    /// - Parameters:
    ///   - name: Name of color table
    ///   - colorPoints: Array with fix color points
    ///   - colorCount: Number of colors
    ///   - defColor: Default color
    init(_ name: String, colorPoints: [RGBAColor], colorCount: Int, defColor: RGBAColor, fixedSize: Bool = true) {
        self.name = name
        self.defColor = defColor
        self.fixedSize = fixedSize
        self.colorPoints = colorPoints
        self.count = self.resize(colorCount: colorCount)
    }
    
    /// Custom decoder. Prevent decoding of color array
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
            
        let name        = try container.decode(String.self, forKey: .name)
        let count       = try container.decode(Int.self, forKey: .count)
        let defColor    = try container.decode(RGBAColor.self, forKey: .defColor)
        let fixedSize   = try container.decode(Bool.self, forKey: .fixedSize)
        let colorPoints = try container.decode([RGBAColor].self, forKey: .colorPoints)

        self.init(name, colorPoints: colorPoints, colorCount: count, defColor: defColor, fixedSize: fixedSize)
    }
    
    /// Clone color table
    /// - Parameter colorCount: Number of colors in table
    /// - Returns: New color table
    func clone(colorCount: Int = 0) -> ColorTableSmooth {
        .init(self.name, colorPoints: self.colorPoints, colorCount: colorCount == 0 ? self.count : colorCount,
              defColor: self.defColor, fixedSize: self.fixedSize)
    }
    
    /// Resize color table
    /// - Parameter colorCount: Number of colors
    /// - Returns: Number of colors (could differ from specified number)
    mutating func resize(colorCount: Int) -> Int {
        var numColors = colorCount
        
        if self.colorPoints.isEmpty {
            // Define default color points
            numColors = max(colorCount, 2)
            self.colorPoints = [RGBAColor(0.3, 0.3, 0.3), .white]
            if numColors > 2 {
                self.colors = RGBAColor.linspace(RGBAColor(0.3, 0.3, 0.3), RGBAColor.white, max(colorCount, self.count))
            }
            else {
                self.colors = self.colorPoints
            }
        }
        else if self.colorPoints.count == 1 {
            // Monochrome palette, set cyclic to true
            numColors = max(colorCount, 1)
            self.colors = Array(repeating: self.colorPoints[0], count: self.count)
        }
        else if self.colorPoints.count > 1 && self.colorPoints.count == colorCount {
            // Palette contains only the color points. No interpolation.
            // This is useful if interpolation between colors happens in color mapper.
            self.colors = self.colorPoints
        }
        else {
            // Smooth palette
            var colorPointCount = self.colorPoints.count
            numColors = max(colorCount, colorPointCount)
            colorPointCount -= 1
            self.colors.removeAll()
            var secSize = Int(numColors / colorPointCount)
            for i in 0..<colorPointCount {
                if secSize + colors.count - 1 > numColors {
                    secSize = numColors - colors.count
                }
                self.colors.append(contentsOf: RGBAColor.linspace(self.colorPoints[i], self.colorPoints[i+1], secSize))
            }
        }
        
        return numColors
    }
    
}
