//
//  NamedBit.swift
//  SwiFractal
//
//  Created by Dirk Braner on 21.11.26.
//

import Foundation

protocol NamedBit : NamedIntEnum {}

extension NamedBit {
    
    /// Return true if raw values are continuously ordered from 0 to n and n < 64
    static var validBits: Bool {
        return allCases.enumerated().allSatisfy { $0.offset == $0.element.rawValue } && allCases.count < Int.bitWidth
    }
    
    /// Return highest bit
    static var highBit: Int {
        assert(Self.validBits, "Invalid bit configuration")
        return allCases.count - 1
    }

    /// Return mask with all bits set
    static var allBits: Int {
        assert(Self.validBits, "Invalid bit configuration")
        return (1 << (allCases.count)) - 1
    }

    /// Return bit value
    var bitValue: Int {
        assert(Self.validBits, "Invalid bit configuration")
        return 1 << rawValue
    }
    
    /// Get bit number from bit name
    /// - Parameter of: Bit name
    /// - Returns: Bit number or nil if bit doesn't exist
    static func bit(of: String) -> Int? {
        assert(Self.validBits, "Invalid bit configuration")
        return allNames.firstIndex(of: of)
    }
    
}


