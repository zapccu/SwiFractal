//
//  ColorTable.swift
//  SwiFractal
//
//  Created by Dirk Braner on 19.11.24.
//

import Foundation
import SwiftUI


///
/// Wrapper for Coloring
///
/// **Create a new coloring**
///
///  `var coloring: EnumColoring = .smooth(colorTable: ColorTableSmooth(...))`
///
///  **Access coloring type specific properties or functions by using** *coloringType*:
///
///  `let colorCount = coloring.coloringType.count`
///
enum EnumColoring : Codable & Equatable {
    
    case smooth(smoothColorTable: ColorTableSmooth)
    case sine(sineColorTable: ColorTableSine)
    case cosine(cosineColoring: CosineColoring)
    case lch(lchColorTable: ColorTableLCH)
    
    /// Returns coloring of associated type
    var coloringType: any Coloring {
        switch self {
        case .smooth(let c): return c
        case .sine(let c): return c
        case .cosine(let c): return c
        case .lch(let c): return c
        }
    }
    
    /// Map floating point value to color depending on Coloring type
    /// - Parameter t: Value in range 0...1. Usually result from *cycle()*
    /// - Returns: Color
    func getColor(t: Double) -> RGBAColor {
        switch self {
        case .smooth(let col):
            return col.getColor(t: t)
        case .sine(let col):
            return col.getColor(t: t)
        case .cosine(let col):
            return col.getColor(t: t)
        case .lch(let col):
            return col.getColor(t: t)
        }
    }
    
    /// Clone a color table with different size
    /// - Parameter colorCount: Number of colors. 0 = Ignore / do not change number of colors.
    /// - Returns: Color table of same type, but different size
    func clone(colorCount: Int = 0) -> EnumColoring {
        switch self {
        case .smooth(let c):
            // c.clone returns ColorTableSmooth, wrap into .smooth
            return .smooth(smoothColorTable: c.clone(colorCount: colorCount))
        case .sine(let c):
            // c.clone returns ColorTableSine, wrap into .sine
            return .sine(sineColorTable: c.clone(colorCount: colorCount))
        case .cosine(let c):
            return .cosine(cosineColoring: c.clone(colorCount: colorCount))
        case .lch(let c):
            return .lch(lchColorTable: c.clone(colorCount: colorCount))
        }
    }

}

enum EnumColoringClass : Codable, Equatable {
    case table
    case calculated
}

///
/// Coloring protocol
///
protocol Coloring: FractalParameters {
    
    /// Return name of coloring
    var name: String { get }
    
    /// Return default color
    var defColor: RGBAColor { get }
    
    /// Return gradient colors
    var gradient: [Color] { get }
    
    /// Return true if coloring is cyclic
    var cyclic: Bool { get }
    
    /// Custom decoder
    init(from decoder: Decoder) throws
    
    /// Return color based on smooth iteration counter in range 0...MaxIter
    //func getColor(smoothIter: Double, scale: Double, offset: Double, ncycle: Double) -> RGBAColor
    
    /// Return color based on transformed iteration counter
    func getColor(t: Double) -> RGBAColor
    
    /// Return color for Int iteration counter in range 0...MaxIter
    func getColor(iter: Int, maxIter: Int) -> RGBAColor
    
    /// Return color for virtual index in range 0...1
    func getColor(vindex: Double) -> RGBAColor
    
}

