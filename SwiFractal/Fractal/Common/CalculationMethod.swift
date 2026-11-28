//
//  DrawMethod.swift
//  SwiFractal
//
//  Created by Dirk Braner on 03.04.26.
//

///
/// Calculation methods
///
enum CalculationMethod : String, CaseIterable, Identifiable {
    case automatic              // Selected by FractalController.resolveMethod() depending on the required precision
    case sequential
    case sequentialPerturbation
    case parallel
    case metalcompute
    
    var id: String { "\(Self.self).\(self.rawValue)" }
}
