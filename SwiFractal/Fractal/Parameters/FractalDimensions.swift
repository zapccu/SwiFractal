//
//  Dimensions.swift
//  SwiFractal
//
//  Created by Dirk Braner on 14.07.26.
//

import Foundation
import SwiftMPx
import Metal64


///
/// Iteration precision type
///
enum DimensionsPrecisionType {
    case double(FractalDimensions<Double>)
    case mpfloat(FractalDimensions<MPFloat>)
}


///
/// Fractal dimension as numeric strings.
/// Used for UI input/output
///
struct StringDimensions {
    
    var cornerX: String = "0"
    var cornerY: String = "0"
    var sizeX: String = "0"
    var sizeY: String = "0"
    
    /// Create FractalDimensions object from string dimensions
    /// - Parameter scale: Scaling factor (max of width / height of image). Default = 1
    /// - Returns: Dimensions precision type
    func toFractalDimensions(scale: Int = 1) -> DimensionsPrecisionType? {
        guard let pr = MPFloat.getPrecision(real: sizeX, scale: scale) else { return nil }

        if pr.isDbl {
            // Double precision
            return .double(FractalDimensions<Double>(
                cornerX: Double(cornerX),
                cornerY: Double(cornerY),
                sizeX: Double(sizeX),
                sizeY: Double(sizeY)
            ))
        }
        else {
            // Arbitrary precision
            return .mpfloat(FractalDimensions<MPFloat>(
                cornerX: MPFloat(cornerX, precision: pr.bits),
                cornerY: MPFloat(cornerY, precision: pr.bits),
                sizeX: MPFloat(sizeX, precision: pr.bits),
                sizeY: MPFloat(sizeY, precision: pr.bits)
            ))
        }
    }
    
}

///
/// Fractal dimensions
///
struct FractalDimensions<RT: PreciseFloatingPoint>: FractalPrecisionParameters, Sendable {
    
    typealias CT = RT.CT
    
    /// Corner real (for calculation)
    var cornerX: RT
    
    /// Corner imaginary (for calculation)
    var cornerY: RT

    /// Corner real as MPFloat (for zooming and precision detection)
    var mpfCornerX: MPFloat { cornerX.toMPFloat(precision: precision.bits ) }
    
    /// Corner imaginary as MPFloat (for zooming and precision detection)
    var mpfCornerY: MPFloat { cornerY.toMPFloat(precision: precision.bits ) }

    /// Size real (for calculation)
    var sizeX: RT
    
    /// Size imaginary (for calculation)
    var sizeY: RT

    /// Return horizontal fractal size as MPFloat (for zooming and precision detection)
    var mpfSizeX: MPFloat { sizeX.toMPFloat(precision: precision.bits ) }

    /// Return vertical fractal size as MPFloat (for zooming and precision detection)
    var mpfSizeY: MPFloat { sizeY.toMPFloat(precision: precision.bits ) }
    
    /// Return reference point for perturbation algorithm
    var refPoint: CT { CT(cornerX + sizeX * 0.5, cornerY + sizeY * 0.5) }
    
    /// Oversampling factor. Range 1...3. 1 = No oversampling
    var oversampling: Int = 1
    
    /// Precision information
    var precision: MPFloat.Precision
    
    /// Render precision strategy
    var renderPrecision: RenderPrecisionStrategy
    
    /// Return dimensions in Double precision
    var asDouble: FractalDimensions<Double> {
        toDouble()
    }
    
    /// Get/set StringDimensions.
    /// Setting StringDimensions will fail if precision required for conversion of StringDimensions is higher than current precision
    var strDimensions: StringDimensions {
        get { self.toString() }
        set {
            if let pr = MPFloat.getPrecision(real: newValue.sizeX) {
                if (RT.self is Double.Type && pr.bits <= 53) || (RT.self is MPFloat.Type) {
                    // If RT == Double, parameter precision is ignored (always 53 bit)
                    // If RT == MPFloat, values are stored with new precision
                    self.cornerX = RT(newValue.cornerX, precision: pr.bits)
                    self.cornerY = RT(newValue.cornerY, precision: pr.bits)
                    self.sizeX = RT(newValue.sizeX, precision: pr.bits)
                    self.sizeY = RT(newValue.sizeY, precision: pr.bits)
                }
            }
        }
    }
    
    /// Return minimum of sizeX and sizeY
    var minSize: RT { RT.min(sizeX, sizeY) }
    
    /// Return corner as complex number (either Cplx or MPComplex)
    var corner: CT { CT(cornerX, cornerY) }
    
    /// Return size as complex number (either Cplx or MPComplex)
    var size: CT { CT(sizeX, sizeY) }
    
    /// Return fractal aspect ratio
    var aspectRatio: Double {
        let ar = sizeX / sizeY
        return ar.toDouble()
    }
    
    /// Return dimensions as FractalDimensions of type MPFloat
    var asMPFloat: FractalDimensions<MPFloat> {
        toMPFloat(precision: precision.bits)
    }
    
    /// Initialize fractal dimensions
    /// - Parameters:
    ///   - resolution: Image resolution
    ///   - cornerX: Left corner of fractal
    ///   - cornerY: Lower corner of fractal
    ///   - sizeX: Width of fractal, must be > 0
    ///   - sizeY: Height of fractal, must be > 0
    ///   - oversampling: Oversampling factor in range 1...3
    init(cornerX: RT, cornerY: RT, sizeX: RT, sizeY: RT, oversampling: Int = 1) {
        let sx = RT.abs(sizeX)
        let sy = RT.abs(sizeY)
        
        let bits = sx.precision
        
        if sx is Double {
            let size = min(sx, sy).asMPFloat
            self.precision = .init(isDbl: true, bits: bits)
            self.renderPrecision = abs(size.exponent) + 8 <= 53 ? .double : .perturbation
        }
        else {
            self.precision = .init(isDbl: false, bits: bits)
            self.renderPrecision = .arbitrary
        }
        
        self.cornerX = cornerX
        self.cornerY = cornerY
        self.sizeX = sx
        self.sizeY = sy
        
        self.oversampling = max(min(oversampling, 3), 1)
    }
    
    /// Convert dimension to Double
    func toDouble() -> FractalDimensions<Double> {
        FractalDimensions<Double>(
            cornerX: cornerX.toDouble(),
            cornerY: cornerY.toDouble(),
            sizeX: sizeX.toDouble(),
            sizeY: sizeY.toDouble(),
            oversampling: oversampling
        )
    }
    
    /// Convert dimensions to MPFloat values with specified precision
    /// - Parameter precision: New precision of dimensions
    /// - Returns: Dimensions as MPFloat values with new precision
    func toMPFloat(precision: Int) -> FractalDimensions<MPFloat> {
        FractalDimensions<MPFloat>(
            cornerX: cornerX.toMPFloat(precision: precision),
            cornerY: cornerY.toMPFloat(precision: precision),
            sizeX: sizeX.toMPFloat(precision: precision),
            sizeY: sizeY.toMPFloat(precision: precision),
            oversampling: oversampling
        )
    }
    
    /// Convert FractalDimension to StringDimensions
    /// - Returns: StringDimensions
    func toString() -> StringDimensions {
        return StringDimensions(
            cornerX: cornerX.toString(),
            cornerY: cornerY.toString(),
            sizeX: sizeX.toString(),
            sizeY: sizeY.toString()
        )
    }
    
    /// Calculate pixel distance
    /// - Parameters:
    ///   - resolution: Resolution of drawing canvas in pixel
    ///   - oversampling: Oversampling factor. Default = -1: use fractal dimensions oversampling factor.
    /// - Returns: Tuple with horizontal and vertical pixel distance
    func pixelDistance(resolution: CGSize, oversampling: Int = -1) -> (RT, RT) {
        let os = oversampling < 1 ? self.oversampling : oversampling
        let width  = Int(resolution.width) * os
        let height = Int(resolution.height) * os
        let dx = sizeX / RT(width - 1, precision: precision.bits)
        let dy = sizeY / RT(height - 1, precision: precision.bits)
        return (dx, dy)
    }
    
    /// Map screen coordinates to fractal point
    /// - Parameters:
    ///   - point: Point (screen coordinates)
    ///   - resolution: Image resolution in pixel
    ///   - oversampling: Oversampling factor. Default = -1: use fractal dimensions oversampling factor.
    /// - Returns: Tuple with fractal coordinates of point
    func mapPoint(_ point: CGPoint, resolution: CGSize, oversampling: Int = -1) -> (RT, RT) {
        let (dx, dy) = pixelDistance(resolution: resolution, oversampling: oversampling)
        let cornerX = cornerX + RT(point.x, precision: precision.bits) * dx
        let cornerY = cornerY + RT(point.y, precision: precision.bits) * dy
        return (cornerX, cornerY)
    }

    /// Map screen size to fractal size
    /// - Parameters:
    ///   - areaSize: Size of an area in pixels
    ///   - resolution: Image resolution in pixel
    ///   - oversampling: Oversampling factor. Default = -1: use fractal dimensions oversampling factor.
    /// - Returns: Tuple with fractal size of area
    func mapSize(_ areaSize: CGSize, resolution: CGSize, oversampling: Int = -1) -> (RT, RT) {
        let (dx, dy) = pixelDistance(resolution: resolution, oversampling: oversampling)
        return (RT(areaSize.width, precision: precision.bits) * dx, RT(areaSize.height, precision: precision.bits) * dy)
    }
    
    /// Fit fractal resolution to aspect ratio of image.
    /// Assumption: No need to change precision
    /// - Parameter resolution: Image size
    /// - Returns: New dimensions
    mutating func fitFractalToImageSize(resolution: CGSize) {
        let pixAspectRatio = Double(resolution.width) / Double(resolution.height)
        guard pixAspectRatio != aspectRatio else { return }
        
        let rtPixAspectRatio = RT(pixAspectRatio, precision: precision.bits)

        if aspectRatio < 1 {
            let newSizeX = sizeY * rtPixAspectRatio
            let delta = (newSizeX - sizeX) * 0.5
            self.cornerX = cornerX - delta
            self.sizeX = newSizeX
        }
        else {
            let newSizeY = sizeX / rtPixAspectRatio
            let delta = (newSizeY - sizeY) * 0.5
            self.cornerY = cornerY - delta
            self.sizeY = newSizeY
        }
    }
    
    /// Fit image resolution to aspect ratio of fractal
    /// - Parameter resolution: Image size
    /// - Returns: New image resolution
    func fitImageToFractalSize(resolution: CGSize) -> CGSize {
        let pixAspectRatio = Double(resolution.width) / Double(resolution.height)
        var newSize = resolution

        if pixAspectRatio == aspectRatio {
            return newSize
        }
        
        if aspectRatio < 1 {
            newSize.width = round(resolution.height * aspectRatio)
        }
        else {
            newSize.height = round(resolution.width / aspectRatio)
        }
        
        return newSize
    }
    
    /// Increase precision based on zoom factor of resolution
    /// - Parameters:
    ///   - resolution: Image resolution
    ///   - area: Selected area withing image resolution
    ///   - safetyBits: Safety bits. Default = 8
    /// - Returns: New precision
    func increasePrecision (resolution: CGSize, area: CGRect, safetyBits: Int = 8) -> MPFloat.Precision {
        var p = precision.bits
        if area.size != resolution {
            let r  = Double(min(resolution.width, resolution.height))
            let rz = Double(max(area.width, area.height))
            p = precision.bits + Int(abs(log2(r/rz))) + safetyBits
        }
        return MPFloat.Precision(isDbl: p <= 53, bits: p)
    }
    
    /// Zoom into screen area
    /// - Parameters:
    ///   - area: Zoom area
    ///   - resolution: Image resolution
    /// - Returns: DimensionsPrecisionType containing the new FractalDimensions object
    func zoomArea(area: CGRect, resolution: CGSize) -> DimensionsPrecisionType {
        // Current precision is sufficient for the calculation of the new dimensions
        // because the smallest possible area size is 1 pixel (current pixel size)
        let (newCornerX, newCornerY) = mapPoint(area.origin, resolution: resolution, oversampling: 1)
        let (newSizeX, newSizeY) = mapSize(area.size, resolution: resolution, oversampling: 1)
        let size = min(newSizeX.toMPFloat(precision: precision.bits), newSizeY.toMPFloat(precision: precision.bits))
 
        debugPrint("Mapping to area \(area)")
        debugPrint("newCornerX: \(newCornerX)")
        debugPrint("newCornerY: \(newCornerY)")

        // Calculate precision requirements for the calculation of the new pixel size
        let pr = RenderPrecisionStrategy.getPrecision(resolution: resolution, size: size)
        if pr.isDbl {
            // Return new dimensions with Double precision
            return .double(FractalDimensions<Double>(
                cornerX: newCornerX.toDouble(),
                cornerY: newCornerY.toDouble(),
                sizeX: newSizeX.toDouble(),
                sizeY: newSizeY.toDouble()
            ))
        }
        else {
            // Return new dimensions with arbitrary precision
            return .mpfloat(FractalDimensions<MPFloat>(
                cornerX: newCornerX.toMPFloat(precision: pr.bits),
                cornerY: newCornerY.toMPFloat(precision: pr.bits),
                sizeX: newSizeX.toMPFloat(precision: pr.bits),
                sizeY: newSizeY.toMPFloat(precision: pr.bits)
            ))
        }
    }
    
    /// Adjust complex area to consider aspect ratio of drawing area
    /// Assumption: No need to change precision
    /// - Parameter resolution: Image resolution in pixel
    func adjustAspectRatio(resolution: CGSize) -> FractalDimensions<RT> {
        let imageRatio   = RT(Int(resolution.width), precision: precision.bits) / RT(Int(resolution.height), precision: precision.bits)
        let fractalRatio = sizeX / sizeY
        
        if fractalRatio == imageRatio { return self }
           
        let fractalHeight = sizeX / imageRatio
        return FractalDimensions<RT>(
            cornerX: cornerX,
            cornerY: cornerY + (sizeY - fractalHeight) * 0.5,
            sizeX: sizeX,
            sizeY: fractalHeight
        )
    }
    
    /// Map screen coordinates to complex coordinates of type Cplx or MPComplex.
    /// Supports real datatypes Double and MPFloat
    /// - Parameters:
    ///   - resolution: Screen resolution without oversampling
    ///   - osSize: Screen resolution considering oversampling
    ///   - aspectRatio: Adjust aspect ratio
    /// - Returns: Linebuffer with complex coordinates
    func mapScreenCoordinates(resolution: CGSize, osSize: ISize, aspectRatio: Bool = false) -> LinearBuffer<CT> {
        let buffer = LinearBuffer<CT>(width: osSize.width, height: osSize.height,
                                      initialValue: .zero(precision: precision.bits))
        
        let newDimensions = aspectRatio ? adjustAspectRatio(resolution: resolution) : self
        let start = newDimensions.corner
        let end   = newDimensions.corner + newDimensions.size
        let realParts = RT.linspace(start.real, end.real, osSize.width)
        let imagParts = RT.linspace(start.imaginary, end.imaginary, osSize.height)
        
        // Initialize linear buffer
        var i = 0
        for y in 0..<osSize.height {
            for x in 0..<osSize.width {
                buffer.pointer[i] = CT(realParts[x], imagParts[y])
                i += 1
            }
        }

        return buffer
    }
    
    /// Map screen coordinates to complex distance values to reference point.
    /// The resulting buffer is used by perturbation algorithm.
    /// - Parameters:
    ///   - refPoint: Reference point
    ///   - resolution: Screen resolution without oversampling
    ///   - osSize: Screen resolution considering oversampling
    ///   - aspectRatio: Adjust aspect ratio
    /// - Returns: Linebuffer with complex distance values
    func mapDeltaScreenCoordinates(refPoint: CT, resolution: CGSize, osSize: ISize, aspectRatio: Bool = true) -> LinearBuffer<CT> {
        let buffer = LinearBuffer<CT>(width: osSize.width, height: osSize.height,
                                      initialValue: .zero(precision: precision.bits))
        
        let newDimensions = aspectRatio ? adjustAspectRatio(resolution: resolution) : self
        let startDelta = newDimensions.corner - refPoint
        let endDelta   = startDelta + newDimensions.size
        let realParts = RT.linspace(startDelta.real, endDelta.real, osSize.width)
        let imagParts = RT.linspace(startDelta.imaginary, endDelta.imaginary, osSize.height)
        
        // Initialize linear buffer
        var i = 0
        for y in 0..<osSize.height {
            for x in 0..<osSize.width {
                buffer.pointer[i] = CT(realParts[x], imagParts[y])
                i += 1
            }
        }

        return buffer
    }

    /// Map screen coordinates to complex coordinates of type Complex2.
    /// Supports real datatype Float2
    /// - Parameters:
    ///   - resolution: Screen resolution without oversampling
    ///   - osSize: Screen resolution considering oversampling
    ///   - aspectRatio: Adjust aspect ratio
    /// - Returns: Linebuffer with complex coordinates
    func mapScreenCoordinates(resolution: CGSize, osSize: ISize, aspectRatio: Bool = false) -> LinearBuffer<Complex2> where RT == Double {
        let buffer = LinearBuffer<Complex2>(width: osSize.width, height: osSize.height, initialValue: .zero)
        
        let newDimensions = aspectRatio ? adjustAspectRatio(resolution: resolution) : self
        let start = newDimensions.corner
        let end   = newDimensions.corner + newDimensions.size
        let realParts = Double.linspace(start.real, end.real, osSize.width)
        let imagParts = Double.linspace(start.imaginary, end.imaginary, osSize.height)
        
        // Initialize matrix
        var i = 0
        for y in 0..<osSize.height {
            for x in 0..<osSize.width {
                buffer.pointer[i] = Complex2(realParts[x], imagParts[y])
                i += 1
            }
        }

        return buffer
    }
    
    /// Map screen coordinates to complex distance values to reference point.
    /// The resulting buffer is used by perturbation algorithm.
    /// - Parameters:
    ///   - refPoint: Reference point as MPComplex value
    ///   - resolution: Screen resolution without oversampling
    ///   - osSize: Screen resolution considering oversampling
    ///   - aspectRatio: Adjust aspect ratio
    /// - Returns: Linebuffer with complex distance values as Float2 where x = real, y = imaginary
    func mapScreenCoordinates(refPoint: Double, resolution: CGSize, osSize: ISize, aspectRatio: Bool = false) -> LinearBuffer<Float2> where RT == Double {
        let buffer = LinearBuffer<Float2>(width: osSize.width, height: osSize.height, initialValue: .zero)
        
        let newDimensions = aspectRatio ? adjustAspectRatio(resolution: resolution) : self
        let startDelta = newDimensions.corner - refPoint
        let endDelta   = refPoint + startDelta
        let realParts = RT.linspace(startDelta.real, endDelta.real, osSize.width)
        let imagParts = RT.linspace(startDelta.imaginary, endDelta.imaginary, osSize.height)
        
        // Initialize linear buffer
        var i = 0
        for y in 0..<osSize.height {
            for x in 0..<osSize.width {
                buffer.pointer[i] = Float2(Float32(realParts[x]), Float32(imagParts[y]))
                i += 1
            }
        }

        return buffer
    }

}

