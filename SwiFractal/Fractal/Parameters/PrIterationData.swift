//
//  PrIterationData.swift
//  SwiFractal
//
//  Created by Dirk Braner on 30.07.26.
//

protocol IterationData: FractalData {
    
    /// Return list of supported calculation methods
    var supportedCalculationMethods: [CalculationMethod] { get }
    
    // Return initial values for Z and C
    // z0: 0 for Mandelbrot, variable value v for Julia
    // c: Variable value v for Mandelbrot, constant point for Julia
    func initialValues(v: CT) -> (z0: CT, c: CT)
    
}
