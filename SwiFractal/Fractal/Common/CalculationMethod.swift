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
    case sequential
    case parallel
    case metalcompute
    
    var id: String { "\(Self.self).\(self.rawValue)" }
}
