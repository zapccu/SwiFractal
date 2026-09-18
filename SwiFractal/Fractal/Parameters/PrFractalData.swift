//
//  FractalData.swift
//  SwiFractal
//
//  Created by Dirk Braner on 19.03.26.
//

import Foundation

//
// Protocol for fractal data (calculation parameters)
// Conforming structures are containers with properties conforming to FractalParameters protocol
//
protocol FractalData<RT>: Codable, Sendable, Equatable {
    
    associatedtype RT: PreciseFloatingPoint
    associatedtype MPFloatVersion: FractalData = Self
    associatedtype DoubleVersion: FractalData = Self
    
    typealias CT = RT.CT
    
    /// Datatype name
    static var dataType: String { get }
    
    /// Data structure with default values
    static var defaultData: Self { get }
    
    /// Name of fractal
    var name: String { get set }
    
    /// Fractal dimensions
    var dimensions: FractalDimensions<RT> { get set }
    
    /// Calculation limits
    var limits: FractalLimits { get set }
    
    /// Coloring
    var colorParameters: FractalColorParameters { get set }
    
    /// Lightning
    var lightParameters: LightningParameters { get set }
    
    /// Return zoom factor
    var zoomFactor: Double { get }
    
    /// Return parameter structure as MPFloat
    var asMPFloat: MPFloatVersion { get }
    
    /// Convert parameter structure to Double
    func toDouble() -> DoubleVersion
    
    /// Convert parameter structure to MPFloat
    func toMPFloat(precision: Int) -> MPFloatVersion
        
}

extension FractalData {
    
    static var dataType: String { String(describing: Self.self) }
    
    /// Return current zoom factor
    var zoomFactor: Double {
        let currentSize = RT.min(dimensions.sizeX, dimensions.sizeY)
        let size = MandelbrotParameters<RT>.defaultData.dimensions.sizeX
        let zf = size / currentSize
        return zf.toDouble()
    }
    
    /// Return max iteration count depending on current zoom level (>= 500)
    var maxIterationCount: Int {
        let lzf = log10(zoomFactor)
        return Int(Double(limits.minIterationCount) + lzf * 200)
    }
    
    /// Return Mandelbrot parameters as MPFloat
    var asMPFloat: MPFloatVersion {
        return self.toMPFloat(precision: self.dimensions.precision.bits)
    }
    
}


//
// Make all decodable types initializable by JSON string
//
extension Decodable {
    
    init?(jsonString: String) {
        guard let data = jsonString.data(using: .utf8) else { return nil }
        do {
            let decoded = try JSONDecoder().decode(Self.self, from: data)
            self = decoded
        } catch {
            debugPrint("Initialization error for type \(Self.self): \(error)")
            return nil
        }
    }
    
}

