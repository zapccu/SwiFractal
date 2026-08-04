//
//  ColorTable.swift
//  SwiFractal
//
//  Created by Dirk Braner on 19.11.24.
//

import Foundation

//
// Wrapper for colortables
//
// Usage:
//
//  var t: EnumColorTable = .smooth(colorTable: ColorTableSmooth(...))
//
//  let colorCount = t.ct.count
//
enum EnumColorTable : Codable & Equatable {
    case smooth(smoothColorTable: ColorTableSmooth)
    case sine(sineColorTable: ColorTableSine)
    
    /// Returns color table
    var ct: any ColorTable {
        switch self {
        case .smooth(let c): return c
        case .sine(let c): return c
        }
    }
    
    /// Clone a color table with different size
    /// - Parameter colorCount: Number of colors
    /// - Returns: Color table of same type, but different size
    func clone(colorCount: Int) -> EnumColorTable {
        switch self {
        case .smooth(let c):
            // c.clone returns ColorTableSmooth, wrap into .smooth
            return .smooth(smoothColorTable: c.clone(colorCount: colorCount))
        case .sine(let c):
            // c.clone returns ColorTableSine, wrap into .sine
            return .sine(sineColorTable: c.clone(colorCount: colorCount))
        }
    }
}

//
// Protocol for color tables
//
protocol ColorTable : FractalParameters {
    
    /// Return name of color table
    var name: String { get }
    
    /// Color array
    var colors: [RGBAColor] { get set }
    
    /// Return default color
    var defColor: RGBAColor { get }
    
    /// Size of color table
    var count: Int { get set }
    
    /// Color table has fixed size
    var fixedSize: Bool { get set }
    
    /// Custom decoder
    init(from decoder: Decoder) throws
    
    /// Return color table entry or default color
    subscript (_: Int, _: Float) -> RGBAColor { get }

    /// Clone color table
    func clone(colorCount: Int) -> Self
    
    /// Resize color table
    mutating func resize(colorCount: Int) -> Int
    
}

extension ColorTable {
    
    /// Return color array converted to RGBA color values
    var rgbaColors: [RGBA] { colors.map { $0.rgba} }
    
    /// Return color table entry at specified index.
    subscript(_ index: Int, _ brightness: Float = 1.0) -> RGBAColor {
        guard index >= 0, index < colors.count else { return defColor }
        return colors[index] * brightness
    }
    
    /// Return color table entry for index in range 0-1 mapped to color table
    subscript(_ index: Double, _ brightness: Float = 1.0) -> RGBAColor {
        let index = Int(max(min(index, 1), 0) * Double(count-1))
        return self[index, brightness]
    }
    
    /// Return color table entry for index in range 0-1 mapped to color table
    subscript(_ index: Float, _ brightness: Float = 1.0) -> RGBAColor {
        return self[Double(index), brightness]
    }
}

//
// Color table
// Default is a table with 1 white color entry
//
struct ColorTableSmooth: ColorTable {
    
    // Do not encode/decode the color array
    enum CodingKeys: String, CodingKey {
        case name, count, defColor, fixedSize, colorPoints
    }
    
    var name: String = "MonoWhite"
    
    // Color array
    internal var colors: [RGBAColor] = [.white]
    
    // Default color
    var defColor: RGBAColor = .black
    
    /// Return number of colors in table
    var count: Int = 1
    
    /// Color table has fixed size
    var fixedSize: Bool = true
    
    // Fixed color points
    var colorPoints: [RGBAColor] = [.white]

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
    func clone(colorCount: Int) -> ColorTableSmooth {
        .init(self.name, colorPoints: self.colorPoints, colorCount: colorCount, defColor: self.defColor, fixedSize: self.fixedSize)
    }
    
    /// Resize color table
    /// - Parameter colorCount: Number of colors
    /// - Returns: Number of colors (could differ from specified number)
    mutating func resize(colorCount: Int) -> Int {
        var numColors = colorCount
        
        if self.colorPoints.isEmpty {
            // Greyscale palette
            numColors = max(colorCount, 2)
            self.colorPoints = [RGBAColor(0.3, 0.3, 0.3), .white]
            self.colors = RGBAColor.linspace(RGBAColor(0.3, 0.3, 0.3), RGBAColor.white, max(colorCount, self.count))
        }
        else if self.colorPoints.count == 1 {
            // Monochrome palette
            numColors = max(colorCount, 1)
            self.colors = Array(repeating: self.colorPoints[0], count: self.count)
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
    
    // Color array
    internal var colors: [RGBAColor] = [ .white ]
    
    // Default color
    var defColor: RGBAColor = .black
    
    var thetas: [Float] = [0.85, 0.0, 0.15]
    
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
    func clone(colorCount: Int) -> ColorTableSine {
        .init(self.name, thetas: self.thetas, colorCount: colorCount, defColor: self.defColor, fixedSize: self.fixedSize)
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
