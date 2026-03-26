//
//  FractalParameters.swift
//  SwiFractal
//
//  Created by Dirk Braner on 24.03.26.
//

protocol FractalParameters : Codable {
    
    static var defaultValues: [String : Any] { get }
    
}
