//
//  PrFractalProtocol.swift
//  SwiFractal
//
//  Created by Dirk Braner on 04.05.26.
//

import Foundation
import SwiftUI
import SwiftMPx
import ParSetKit


//
// Protocol for fractals
//
@MainActor
@dynamicMemberLookup
protocol FractalProtocol: AnyObject {
    
    // Type of fractal parameters
    associatedtype DataType: FractalData

    // Type of calculation results
    associatedtype ResultType: CalculationResult
    
    associatedtype RT: PreciseFloatingPoint
    
    associatedtype CT: ComplexNumber
        
    // Return default dimensions of fractal type
    static var defaultDimensions: FractalDimensions<Double> { get }
    
    // Return fractal type as String
    var fractalType: String { get }
    
    // Set of fractal parameters
    var FP: ParSet<DataType> { get set }
        
    // Return number of available parameter versions
    var versionsCount: Int { get }
    
    // Check if current parameter set version has been modified
    var hasChanges: Bool { get }
    
    //
    // Parameterset operations
    //
    
    // Switch back to previous parameter version
    func undo()
    
    // Switch back to initial parameter version
    func reset()
    
    // Return dimension with arbitrary precision
    func getDimensions() -> FractalDimensions<MPFloat>
    
    // Return color parameters
    func getColorParameters() -> FractalColorParameters
    
    // Return color table
    func getColoring() -> EnumColoring
    
    // Return limits
    func getLimits() -> FractalLimits
    
    // Return lightning parameters
    func getLightningParameters() -> LightningParameters
    
    // Return calculation methods supported by the fractal type
    func getSupportedCalculationMethods() -> [CalculationMethod]
    
    func fitDimensionsToImageSize(resolution: CGSize)
    
    func fitImageSizeToDimensions(resolution: CGSize) -> CGSize
    
    // Mark start of calculation.
    // Return dynamic calculation parameters
    func beginCalculation(resolution: CGSize, progress: CalculationProgress) -> DynamicParameters<DataType>?

    // Calculate fractal
    func calculate(method: CalculationMethod, resolution: CGSize, progress: CalculationProgress) async -> CombinedResult
    
    // Mark end of calculation.
    // Define this function in a fractal class if anything must be
    // cleaned up after calculation is finished.
    func endCalculation()
    
    // Map pixel coordinates to complex point.
    // Return point as tuple of Strings
    func mapPointFormatted(_ location: CGPoint, resolution: CGSize) -> (String, String)

}

extension FractalProtocol {
    
    /// Subscript for colorParameters
    subscript<T>(dynamicMember keyPath: WritableKeyPath<FractalColorParameters, T>) -> T {
        get { FP.colorParameters[keyPath: keyPath] }
        set { FP.colorParameters[keyPath: keyPath] = newValue }
    }

    /// Subscript for lightParameters
    subscript<T>(dynamicMember keyPath: WritableKeyPath<LightningParameters, T>) -> T {
        get { FP.lightParameters[keyPath: keyPath] }
        set { FP.lightParameters[keyPath: keyPath] = newValue }
    }
    
    /// Subscript for limits
    subscript<T>(dynamicMember keyPath: WritableKeyPath<FractalLimits, T>) -> T {
        get { FP.limits[keyPath: keyPath] }
        set { FP.limits[keyPath: keyPath] = newValue }
    }
    
    /// Switch back to previous parameter set
    func undo() { FP.undo() }
    
    /// Reset parameters to initial version
    func reset() { FP.reset() }
    
    /// Return number of parameter set versions
    var versionsCount: Int { FP.versionsCount }
    
    /// Return true if current parameter set has been modified
    var hasChanges: Bool { FP.hasChanges }
        
    /// Return fractal dimensions
    func getDimensions() -> FractalDimensions<MPFloat> { FP.current.dimensions.asMPFloat }
    
    /// Return coloring parameters
    func getColorParameters() -> FractalColorParameters { FP.colorParameters }
    
    /// Return color table
    func getColoring() -> EnumColoring { FP.colorParameters.coloring }
    
    /// Return fractal limits
    func getLimits() -> FractalLimits { FP.limits }
    
    /// Return lightning parameters
    func getLightningParameters() -> LightningParameters { FP.lightParameters }
    
    /// Return calculation methods supported by the fractal type
    func getSupportedCalculationMethods() -> [CalculationMethod] { FP.current.supportedCalculationMethods }
    
    /// Map fractal dimensions to image resolution
    /// - Parameter resolution: Image resolution
    func fitDimensionsToImageSize(resolution: CGSize) {
        FP.dimensions.fitFractalToImageSize(resolution: resolution)
    }
    
    /// Map image resolution to fractal dimensions
    /// - Parameter resolution: Current image resolution
    /// - Returns: New image resolution
    func fitImageSizeToDimensions(resolution: CGSize) -> CGSize {
        return FP.dimensions.fitImageToFractalSize(resolution: resolution)
    }
    
    /// Map point to complex coordinates
    /// - Parameters:
    ///   - point: Point on screen
    ///   - resolution: Frame resolution
    /// - Returns: Tuple of Strings
    func mapPointFormatted(_ point: CGPoint, resolution: CGSize) -> (String, String) {
        let (x, y) = FP.dimensions.mapPoint(point, resolution: resolution, oversampling: 1)
        return (x.toString(), y.toString())
    }
    
    
/// Mark start of calculation. Prepare calculation parameters
/// - Parameters:
///   - size: Output graphics size
///   - progress: Calculation progress
/// - Returns: true if calculation parameters prepared successfully
func beginCalculation(resolution: CGSize, progress: CalculationProgress) -> DynamicParameters<DataType>? {
    let settingsSnapshot = AppSettings.shared.snapshot()
    return DynamicParameters<DataType>(anypar: FP.current, resolution: resolution, progress: progress,
                                       settings: settingsSnapshot)
}

    /// Mark end of calculation. Default implementation does nothing.
    func endCalculation() {
        // Does nothing by default
    }
    
}


