//
//  PrBasicCalculations.swift
//
//  Created by Dirk Braner on 08.05.26.
//

///
/// Protocol with basic calculation functions
///
protocol BasicCalculations {
    
    // Return zero value
    static var zero: Self { get }
    
    static func + (_ lhs: Self, _ rhs: Self) -> Self
    static func - (_ lhs: Self, _ rhs: Self) -> Self
    static func * (_ lhs: Self, _ rhs: Self) -> Self
    static func * (_ lhs: Self, _ rhs: Double) -> Self
    static func / (_ lhs: Self, _ rhs: Self) -> Self
    static func / (_ lhs: Self, _ rhs: Double) -> Self
    
    static func == (_ lhs: Self, _ rhs: Self) -> Bool
    static func != (_ lhs: Self, _ rhs: Self) -> Bool

    static func < (_ lhs: Self, _ rhs: Self) -> Bool
    static func > (_ lhs: Self, _ rhs: Self) -> Bool
    
}
