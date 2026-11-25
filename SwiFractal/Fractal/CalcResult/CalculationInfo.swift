//
//  CalculationInfo.swift
//  SwiFractal
//
//  Created by Dirk Braner on 17.10.26.
//


import Foundation


///
/// Calculation states
///
enum EnumCalculationState: Int, NamedBit {
    case idle
    case completed
    case inProgress
    case cancelled
    case error
}
typealias CalculationState = BitSet<EnumCalculationState>


///
/// Calculation result content
///
enum EnumResultContains: Int, NamedBit {
    case standard   // Result contains only standard values
    case orbits     // Result contains orbit/period values
    case stripes    // Result contains stripe values
}
typealias ResultContains = BitSet<EnumResultContains>


///
/// Additional information for calculation result matrix
///
struct CalculationInfo: Sendable {
    
    /// Messages related to calculation state
    static let messages: [EnumCalculationState:String] = [
        .idle: "Idle",
        .completed: "Completed",
        .inProgress: "In Progress",
        .cancelled: "Cancelled",
        .error: "Error"
    ]
    
    /// Calculation state
    var state: CalculationState = [.idle]
    
    /// Additional information stored in each calculation result
    var extendedInfo: ResultContains = []
    
    /// Message related to state
    var message: String = ""
        
    /// Number of errors
    var errorCount: Int = 0
    
    init(state: EnumCalculationState, extendedInfo: ResultContains = [], message: String = "", errorCount: Int = 0) {
        self.state = [state]
        self.extendedInfo = extendedInfo
        self.message = message
    }
    
    /// Return message
    func getMessage() -> String {
        guard message.isEmpty else { return message }
        var msg: String = ""
        
        for s in EnumCalculationState.allCases {
            if state.isSet(s) {
                if !msg.isEmpty { msg += "|" }
                msg += Self.messages[s] ?? "Unknown state"
            }
        }
        
        return msg

    }
    
}
