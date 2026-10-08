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
    func calculate(method: CalculationMethod, resolution: CGSize) async -> (CalculationState, Matrix<MandelbrotResult>?) {
        // Get calculation function for specified method
        guard let function = FractalCalculation<DataType>.getFunction(method: method, P: FP.current)  else {
            return (.error("Calculation method not supported"), nil)
        }
        
        // Setup calculation, create dynamic calculation parameters
        guard let DP = beginCalculation(resolution: resolution) else {
            return (.error("Setup of calculation environment failed"), nil)
        }
        
        // Calculate the fractal
        let result = await function(DP)
        
        endCalculation()
        
        return (.completed(), result)
    }

}
