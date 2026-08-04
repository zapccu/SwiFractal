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
protocol FractalProtocol {
    
    // Type of fractal parameters
    associatedtype DataType: IterationData
    
    // Type of calculation results
    associatedtype ResultType: CalculationResult
    
    // Type of dynamic parameters
    associatedtype DynParType: PrDynamicParameters
    
    associatedtype RT: PreciseFloatingPoint
    
    associatedtype CT: ComplexNumber
    
    //typealias CalculationFunction = @Sendable (DynParType) async -> Matrix<ResultType>
    
    //nonisolated static var calculationFunctions: [CalculationMethod: CalculationFunction] { get }
    
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
    
    // Current image
    //var image: CGImage? { get set }
    
    // Zoomed image
    // var zoomedImage: CGImage? { get set }
    
    //
    // Parameterset operations
    //
    
    // Switch back to previous parameter version
    mutating func undo()
    
    // Switch back to initial parameter version
    mutating func reset()
    
    // Return dimension with arbitrary precision
    func getDimensions() -> FractalDimensions<MPFloat>
    
    // Return color table
    func getColorTable() -> EnumColorTable
    
    mutating func fitDimensionsToImageSize(resolution: CGSize)
    
    func fitImageSizeToDimensions(resolution: CGSize) -> CGSize
    
    // Mark start of calculation.
    // Return dynamic calculation parameters
    func beginCalculation(resolution: CGSize) -> DynParType?
    
    // Render fractal
    func render(method: CalculationMethod, resolution: CGSize) async -> (CalculationState, CGImage?)
    
    // Mark end of calculation.
    // Define this function in a fractal class if anything must be
    // cleaned up after calculation is finished.
    func endCalculation()
    
    // Map pixel coordinates to complex point.
    // Return point as tuple of Strings
    func mapPointFormatted(_ location: CGPoint, resolution: CGSize) -> (String, String)
    
    // Draw calculation result
    func drawResultSet(result: Matrix<ResultType>, resolution: CGSize, size: ISize, mapper: ColorMapper) -> CGImage?
    
    // Zoom into fractal.
    // Return new fractal with different precision
    func zoom(into area: CGRect, resolution: CGSize) -> any FractalProtocol

}

extension FractalProtocol {
    
    /// Switch back to previous parameter set
    mutating func undo() { FP.undo() }
    
    /// Reset parameters to initial version
    mutating func reset() { FP.reset() }
    
    /// Return number of parameter set versions
    var versionsCount: Int { FP.versionsCount }
    
    /// Return true if current parameter set has been modified
    var hasChanges: Bool { FP.hasChanges }
        
    /// Return fractal dimensions
    func getDimensions() -> FractalDimensions<MPFloat> { FP.current.dimensions.asMPFloat }
    
    /// Return color table
    func getColorTable() -> EnumColorTable { FP.coloring.colorTable }
    
    mutating func fitDimensionsToImageSize(resolution: CGSize) {
        FP.dimensions.fitFractalToImageSize(resolution: resolution)
    }
    
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
    
    /// Mark end of calculation. Default implementation does nothing.
    func endCalculation() {
        // Does nothing
    }
    
}


