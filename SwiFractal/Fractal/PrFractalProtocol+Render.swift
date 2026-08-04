//
//  PrFractalProtocol+Render.swift
//  SwiFractal
//
//  Created by Dirk Braner on 30.07.26.
//

import Foundation
import SwiftUI

//
// Extend FractalProtocol by render functions
//
extension FractalProtocol where DynParType == DynamicParameters<DataType> {

    /// Render fractal
    /// - Parameters:
    ///   - method: Calculation method
    ///   - resolution: Image resolution
    /// - Returns: Tuple of calculation state and image
    func render(method: CalculationMethod, resolution: CGSize) async -> (CalculationState, CGImage?) {
        // Get calculation function for specified method
        guard let function = FractalCalculation<DataType>.getFunction(method: method, P: FP.current)  else {
            return (.error("Calculation method not supported"), nil)
        }
        
        // Setup calculation, create dynamic calculation parameters
        guard let DP = beginCalculation(resolution: resolution) else {
            return (.error("Setup of calculation environment failed"), nil)
        }
        
        // Calculate fractal
        let result = await function(DP)
        
        // Calculate color histogram
        let histogram = Histogram(result: result, maxValue: DP.limits.iterations)
        
        // Create color mapper
        let mapper = ColorMapper(coloring: DP.coloring, limits: DP.limits, histogram: histogram, lightning: DP.lightning)
        
        // Draw the image
        if let image = drawResultSet(result: result, resolution: resolution, size: DP.osSize, mapper: mapper) {
            endCalculation()
            return (.completed(), image)
        }
        else {
            endCalculation()
            return (.error("Failed to draw fractal"), nil)
        }
    }
    
    /// Draw results into graphics
    /// - Parameters:
    ///   - result: Matrix containing calculation results
    ///   - resolution: Final image resolution without oversampling
    ///   - size: Image size considering oversampling factor
    ///   - mapper: Colormapper object
    /// - Returns: Image or nil on error
    func drawResultSet(result: Matrix<MandelbrotResult>, resolution: CGSize, size: ISize, mapper: ColorMapper) -> CGImage? {
        // Create graphics device
        let graphics = ImageGraphics(frameSize: resolution, size: size)

        let cgImage = graphics.beginDraw {
            graphics.clear(color: .blue)
            
            for y in 0..<result.rows {
                // Set point to start of line.
                // We do not use graphics.move() because we'll parallelize the drawing in the future
                var point: IPoint = IPoint(x: 0, y: y)
                
                // Color of first point in line
                var currentResult = result[y, 0]
                var color = mapper.mapResult(result: currentResult)
                
                for x in 1..<result.cols {
                    let r = result[y, x]
                    if r == currentResult { continue }
                    currentResult = r
                    let newColor = mapper.mapResult(result: currentResult)
                    if newColor != color {
                        graphics.drawHLine(from: point, to: x, color: color)
                        point.x = x
                        color = newColor
                    }
                }
                
                // Draw rest of line
                graphics.drawHLine(from: point, to: graphics.width, color: color)
            }
            
            return graphics.cgImage
        }
        
        return cgImage
    }

}
