//
//  PrResult.swift
//  SwiFractal
//
//  Created by Dirk Braner on 02.05.26.
//

//
// Protocol for calculation results
//
protocol CalculationResult : Equatable & Sendable {
    
    /// Return histogram value of result
    var histValue: Double { get }
    
    /// Return true, if calculation result contains a valid histogram value
    var hasValidHistValue: Bool { get }
    
    static var zero: Self { get }
    static var defaultValue: Self { get }
    
}


