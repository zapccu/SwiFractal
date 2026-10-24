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
extension FractalProtocol { // where DynParType == DynamicParameters<DataType> {

    /// Calculate fractal
    /// - Parameters:
    ///   - method: Calculation method
    ///   - resolution: Image resolution
    /// - Returns: Tuple of calculation state and result
    func calculate(method: CalculationMethod, resolution: CGSize) async -> CombinedResult {
        // Get calculation function for specified method
        guard let function = FractalCalculation<DataType>.getFunction(method: method, P: FP.current)  else {
            return (
                nil,
                CalculationInfo(state: .error, message: "Calculation method not supported")
            )
        }
        
        // Setup calculation, create dynamic calculation parameters
        guard let DP = beginCalculation(resolution: resolution) else {
            return (
                nil,
                CalculationInfo(state: .error, message: "Setup of calculation environment failed")
            )
        }
        
        // Calculate the fractal
        let combinedResult = await function(DP)
        
        endCalculation()
        
        return combinedResult
    }

}
