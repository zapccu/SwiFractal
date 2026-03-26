//
//  FractalData.swift
//  SwiFractal
//
//  Created by Dirk Braner on 19.03.26.
//

//
// Protocol for fractal data
//
protocol FractalData: Codable & Sendable {
    
    /// Datatype name
    static var dataType: String { get }
    
    /// Dictionary with default values
    static var defaultValues: [String: Any] { get }
    
    /// Data structure with default values
    static var defaultData: Self { get }
    
    /// Parameters common to all fractal types
    var common: CommonParameters { get set }
    
}


