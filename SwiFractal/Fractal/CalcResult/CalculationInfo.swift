//
//  CalculationInfo.swift
//  SwiFractal
//
//  Created by Dirk Braner on 17.10.26.
//


import Foundation


///
/// Additional information for fractal calculation result
///
struct CalculationState: OptionSet, Bitmaskable, Sendable {
    
    let rawValue: Int
    
    static let idle = CalculationState(rawValue: 1)
    static let completed = CalculationState(rawValue: 2)
    static let inProgress = CalculationState(rawValue: 4)
    static let cancelled = CalculationState(rawValue: 8)
    static let error = CalculationState(rawValue: 16)
    
    static let allCases: [CalculationState] = [.idle, .completed, .inProgress, .cancelled, .error]

}

struct CalculationInfo: Sendable {
    
    /// Calculation state
    var state: CalculationState = .idle
    
    /// Message related to state
    var message: String = ""
        
    /// Number of errors
    var errorCount: Int = 0
    
}
