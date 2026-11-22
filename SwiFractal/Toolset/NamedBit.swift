//
//  NamedBit.swift
//  SwiFractal
//
//  Created by Dirk Braner on 21.11.26.
//

import Foundation

protocol NamedBit : NamedIntEnum {}

extension NamedBit {
    
    static var highBit: Int { allCases.count - 1 }

    /// Return mask with all bits set
    static var allBits: Int { (1 << (allCases.count)) - 1 }

    /// Return bit value
    var bitValue: Int { 1 << rawValue }
    
    /// Get bit number from bit name
    static func bit(of: String) -> Int? {
        allNames.firstIndex(of: of) ?? nil
    }
    
}
