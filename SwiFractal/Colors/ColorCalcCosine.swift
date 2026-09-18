//
//  CalculatedCosineColoring.swift
//  SwiFractal
//
//  Created by Dirk Braner on 17.08.26.
//

import Foundation
import SwiftUI


/// Cosine coloring parameters
struct CosineColoringParameters: FractalParameters {
    var offset: SIMD3<Float>
    var amplitude: SIMD3<Float>
    var frequency: SIMD3<Float>
    var phase: SIMD3<Float>
}

///
/// Cosine coloring
///
struct CosineColoring : CalculatedColoring, FractalParameters {

    enum CodingKeys: String, CodingKey {
        case name, defColor, parameters
    }

    var name: String = "Cosine_Rainbow"

    // Cosine coloring parameters a, b, c, d
    var parameters: CosineColoringParameters = CosineColoringParameters(
        offset: SIMD3f(0.5, 0.5, 0.5),
        amplitude: SIMD3f(0.5, 0.5, 0.5),
        frequency: SIMD3f(1.0, 1.0, 1.0),
        phase: SIMD3f(0.0, 0.33, 0.67)
    )
    
    /// Convenient access to cosine coloring parameters
    var a: SIMD3f { parameters.offset }
    var b: SIMD3f { parameters.amplitude }
    var c: SIMD3f { parameters.frequency }
    var d: SIMD3f { parameters.phase }
    
    /// Cosine coloring is always cyclic
    var cyclic: Bool { true }
    
    /// Default color
    var defColor: RGBAColor = .black
    
    /// Return gradient with 256 colors
    var gradient: [Color] {
        let t = Double.linspace(0.0, 1.0, 256)
        return t.map { getColor(t: $0).color }
    }
    
    /// Init a cosine calculated coloring
    /// - Parameters:
    ///   - name: Name of coloring
    ///   - offset: Average brightness / color (base value)
    ///   - amplitude: Strength of color amplitude around offset
    ///   - frequency: Repeating factor of channel in interval 0...1
    ///   - phase: Phase shift between the channels. Creates the different colors
    ///   - defColor: Default color
    init(_ name: String, offset: RGB, amplitude: RGB, frequency: RGB, phase: RGB, defColor: RGBAColor) {
        self.name = name
        self.parameters = CosineColoringParameters(offset: offset, amplitude: amplitude, frequency: frequency, phase: phase)
        self.defColor = defColor
    }
    
    /// Init a cosine calculated coloring
    /// - Parameters:
    ///   - name: Name of coloring
    ///   - parameters: Cosine coloring parameters (tuple of 4 Floats representing a/offset, b/amplitude ,c/frequency, d/phase)
    ///   - defColor: Default color
    init(_ name: String, parameters: CosineColoringParameters, defColor: RGBAColor) {
        self.name = name
        self.parameters = parameters
        self.defColor = defColor
    }
    
    /// Custom decoder
    /// - Parameter decoder: Decoder
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
            
        let name = try container.decode(String.self, forKey: .name)
        let defColor = try container.decode(RGBAColor.self, forKey: .defColor)
        let parameters = try container.decode(CosineColoringParameters.self, forKey: .parameters)

        self.init(name, parameters: parameters, defColor: defColor)
    }
    
    /// Clone color table
    /// - Parameter colorCount: Number of colors in table. Ignored.
    /// - Returns: New color table
    func clone(colorCount: Int = 0) -> CosineColoring {
        .init(self.name, parameters: self.parameters, defColor: defColor)
    }
    
    /// Calculate color using cosine based on Inigo Quilez cosine coloring algorithm
    /// - Parameters:
    ///   - smoothIter: Smooth iteration value in range 1...MaxIter. Usually result of *compress()*
    ///   - scale: Frequency of color changing
    ///   - offset: Offset to first value in color table
    ///   - ncycle: Defines how many iterations correlate with 1 cycle. Modulo division by ncycle allows to determine after how many (transformed)
    ///   iteration steps the color repeats, regardless of the absolute iteration depth. 1 = Full color cycle every 1 iteration (default).
    ///   ncycle must be >= 1.
    /// - Returns: Mapped color value
    /// - Note: Parameters *scale* and *ncycle* are more or less equivelant. But they have different numeric ranges.
    /*
    func getColor(smoothIter: Double, scale: Double, offset: Double, ncycle: Double) -> RGBAColor {
        let sc: Double = scale.clamped(to: 0.01...50.0)
        let nc = max(ncycle, 1.0)
        let t = (fmod(smoothIter * sc + offset, nc) / nc).clamped
        
        // 2 * π * (c * t + d)
        let tau: Float = 2.0 * .pi
        let inner = tau * (c * Float(t) + d)
            
        let cosVector = SIMD3f(
            cos(inner.x),
            cos(inner.y),
            cos(inner.z)
        )

        // a + b * cos(...)
        let rgb = a + b * cosVector
        return RGBAColor(rgb: rgb.clamped)
    }
     */
    
    /// Get color base on transformed iteration counter
    /// - Parameter t: Transformed smooth iteration counter in range 0...1
    /// - Returns: Color
    func getColor(t: Double) -> RGBAColor {
        // 2 * π * (c * t + d)
        let tau: Float = 2.0 * .pi
        let inner = tau * (c * Float(t) + d)
            
        let cosVector = SIMD3f(
            cos(inner.x),
            cos(inner.y),
            cos(inner.z)
        )

        // a + b * cos(...)
        let rgb = a + b * cosVector
        return RGBAColor(rgb: rgb.clamped)
    }
    
    /// Get color based on integer iteration counter considering cyclic and non cyclic color tables
    /// - Parameters:
    ///   - iter: Iteration counter
    ///   - maxIter: Max iterations
    /// - Returns: Color
    func getColor(iter: Int, maxIter: Int = 0) -> RGBAColor {
        guard iter > 0 && maxIter >= iter else { return defColor }
        let t = Double(iter) / Double(maxIter)
        return getColor(t: t)
    }
    
    func getColor(vindex: Double) -> RGBAColor {
        return getColor(t: vindex.clamped)
    }
    
}

