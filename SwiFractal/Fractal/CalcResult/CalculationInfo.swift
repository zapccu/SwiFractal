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
    
    /// No calculation in progress
    static let idle = CalculationState(rawValue: 1)
    
    /// Calculation completed
    static let completed = CalculationState(rawValue: 2)
    
    /// Calculation in progress
    static let inProgress = CalculationState(rawValue: 4)
    
    /// Calculation cancelled by user
    static let cancelled = CalculationState(rawValue: 8)
    
    /// Error during calculation
    static let error = CalculationState(rawValue: 16)
    
    static let allCases: [CalculationState] = [.idle, .completed, .inProgress, .cancelled, .error]

}

enum EnumResultContains: Int, CaseIterable {
    case none
    case orbits
    case stripes
}
typealias ResultContains = BitSet<EnumResultContains>

///
/// Additional information for calculation result matrix
///
struct CalculationInfo: Sendable {
    
    /// Calculation state
    var state: CalculationState = .idle
    
    /// Additional information stored in each calculation result
    var extendedInfo: ResultContains = []
    
    /// Message related to state
    var message: String = ""
        
    /// Number of errors
    var errorCount: Int = 0
    
}
