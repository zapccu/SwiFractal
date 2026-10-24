//
//  ColorTableStatic.swift
//  SwiFractal
//
//  Created by Dirk Braner on 16.10.26.
//

import Foundation
import SwiftUI


///
/// Static color table.
/// Default is a table with 1 white color entry.
///
struct ColorTableStatic: ColorTable {
    
    // Do not encode/decode the color array
    enum CodingKeys: String, CodingKey {
        case name, defColor, fixedSize, colors
    }
    
    // Color table name
    var name: String = "StaticWhite"
    
    // Color array
    var colors: [RGBAColor] = [.white]
    
    // Default color
    var defColor: RGBAColor = .black
    
    /// Return number of colors in table
    var count: Int {
        get { self.colors.count }
        set { _ = self.resize(colorCount: newValue) }
    }
    
    /// Color table has fixed size
    var fixedSize: Bool = true
    
    /// Color table is cyclic
    var cyclic: Bool {
        self.colors.count == 1 || (self.colors.count > 2 && self.colors.first != self.colors.last)
    }
    
    /// Return gradient colors
    var gradient: [Color] {
        return self.colors.map(\.color)
    }

    /// Init color table from color array
    /// - Parameters:
    ///   - name: Name of color table
    ///   - colors: Array with colors
    ///   - defColor: Default color
    init(_ name: String, colors: [RGBAColor], defColor: RGBAColor, fixedSize: Bool = true) {
        self.name = name
        self.defColor = defColor
        self.fixedSize = fixedSize
        self.colors = colors
    }
    
    init(_ name: String, colors: [Int], defColor: RGBAColor, fixedSize: Bool = true) {
        self.colors = colors.map {
            let b = Float($0 & 0xFF) / 255.0
            let g = Float(($0 >> 8) & 0xFF) / 255.0
            let r = Float(($0 >> 16) & 0xFF) / 255.0
            return RGBAColor(r, g, b)
        }
    }
    
    /// Custom decoder. Prevent decoding of color array
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
            
        let name      = try container.decode(String.self, forKey: .name)
        let defColor  = try container.decode(RGBAColor.self, forKey: .defColor)
        let fixedSize = try container.decode(Bool.self, forKey: .fixedSize)
        let colors    = try container.decode([RGBAColor].self, forKey: .colors)

        self.init(name, colors: colors, defColor: defColor, fixedSize: fixedSize)
    }
    
    /// Clone color table
    /// - Parameter colorCount: Number of colors in table (ignored)
    /// - Returns: New color table
    func clone(colorCount: Int = 0) -> ColorTableStatic {
        .init(self.name, colors: self.colors, defColor: self.defColor, fixedSize: self.fixedSize)
    }
    
    /// Resize color table
    /// - Parameter colorCount: Number of colors
    /// - Returns: Number of colors (could differ from specified number)
    mutating func resize(colorCount: Int) -> Int {
        guard colorCount > 0 && colorCount != colors.count else {
            return colors.count
        }
        
        if colorCount > colors.count {
            while colors.count < colorCount {
                colors += colors
            }
            colors.removeLast(colors.count - colorCount)
        }
        else if colors.count - colorCount > 0 {
            colors.removeLast(colors.count - colorCount)
        }
        
        return colors.count
    }
    
}
