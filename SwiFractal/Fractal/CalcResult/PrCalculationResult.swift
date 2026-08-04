//
//  PrResult.swift
//  SwiFractal
//
//  Created by Dirk Braner on 02.05.26.
//

//
// Protocol for calculation results
//
protocol CalculationResult : Equatable & BitwiseCopyable & Sendable {
    
    static var zero: Self { get }
    static var defaultValue: Self { get }
    
}

