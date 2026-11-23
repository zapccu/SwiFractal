//
//  BitSet.swift
//
//  Created by Dirk Braner on 07.02.26.
//

import Foundation


///
/// BitSet can be used to store values of a given enum as a bitmask.
/// The rawValue of the enum must be of type Int and must be conform to protocol CaseIterable.
///
/// Example:
///
///     enum EnumDrawingAttributes: Int, NamedBit {
///         case solid
///         case rounded
///         case colored
///         case filled
///     }
///
///     var bitMask: BitSet<EnumDrawingAttributes> = [.solid, .colored]
///
/// With type alias:
///
///     typealias DrawingAttributes = BitSet<EnumDrawingAttributes>
///     
///     var bitMask: DrawingAttributes = [.solid, .colored]
///
/// BitSet is conform to Codable. A bitmask is converted to a JSON array containing the names of the bits.
///
struct BitSet<T: NamedBit>: ExpressibleByArrayLiteral, Equatable, Codable {
        
    /// The bit mask
    var mask: Int = 0
    
    /// Return bits as Array of named bits
    var bits: [T] { T.allCases.filter { $0.bitValue & mask != 0 } }
    
    /// Return true if no bit is set
    var noneSet: Bool { mask == 0 }
    
    /// Return true if all bits are set
    var allSet: Bool { mask == T.allBits }
    
    /// Init with bit. If bit number is > highest bit number or < 0, initialize with 0
    init(_ bit: T) {
        self.mask = bit.bitValue
    }
    
    /// Init with bit mask raw value without bit conversion. Bits > highBit are masked.
	init(rawValue: Int) {
        self.mask = rawValue & T.allBits
	}
    
    /// Init from String array
    /// - Parameter values: Array of bit names
    init?(_ values: [String]) {
        self.mask = 0
        for value in values {
            guard let bit = T.bit(of: value) else { return nil }
            self.mask |= 1 << bit
        }
    }

    /// Initialize bitset with multiple bits by using a bitwise OR operation
    /// Example: bitset = [.bit1, .bit2 ]
    /// This function is also called for decoding keyed JSON strings like "{ \"key\": [ \"case1\”, \"case2\" ] }"
    init(arrayLiteral elements: T...) {
        self.mask = elements.reduce(0) { $0 | $1.bitValue }
    }
    
    /// Set bit
    @inline(__always)
    mutating func set(_ bit: T) {
        self.mask |= bit.bitValue
    }
    
    /// Clear bit
    @inline(__always)
    mutating func clear(_ bit: T) {
        self.mask &= ~bit.bitValue
    }
    
    /// Toggle bit
    @inline(__always)
    mutating func toggle(_ bit: T) {
        self.mask ^= bit.bitValue
    }
    
    /// Set mask to single bit
    @inline(__always)
    mutating func set(to bit: T) {
        self.mask = bit.bitValue
    }
    
    /// Check if bit is not set
    /// - Parameter bit: Named bit
    /// - Returns: true if bit is not set, otherwise false
    @inline(__always)
    func notSet(_ bit: T) -> Bool {
        return self.mask & bit.bitValue == 0
    }
    
    /// Check if bit is set
    /// - Parameter bit: Named bit
    /// - Returns: true if bit is set, otherwise false
    @inline(__always)
    func isSet(_ bit: T) -> Bool {
        return self.mask & bit.bitValue != 0
    }
    
    /// Test if all bits in array are set
    /// - Parameter bits: Array with named bits
    /// - Returns: true if all bits are set, otherwise false
    @inline(__always)
    func allSet(_ bits: [T]) -> Bool {
        return bits.allSatisfy( { self.mask & $0.bitValue != 0} )
    }
    
    /// Test if any bit in array is set
    /// - Parameter bits: Array with named bits
    /// - Returns: true if at least one bit is set, otherwise false
    @inline(__always)
    func anySet(_ bits: [T]) -> Bool {
        return bits.contains(where: { self.mask & $0.bitValue != 0 } )
    }

    /// Put bitset bit-names as String array into JSON instead of rawValue
    /// - Parameter encoder: Encoder
    func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()
        let names = T.allCases.filter { self.mask & $0.bitValue != 0 }.map { $0.name }
        try container.encode(contentsOf: names)
    }
    
    /// Decode from JSON array
    /// This function is called for keyless JSON arrays like "[ \"case1\", \"case2\" ]"
    init(from decoder: Decoder) throws {
        // Open an unkeyedContainer for reading the array
        var container = try decoder.unkeyedContainer()
        self.mask = 0

        // Iterate through the array
        while !container.isAtEnd {
            let value = try container.decode(String.self)
            if let bit = T.bit(of: value) {
                self.mask |= 1 << bit
            }
        }
    }
    
    /// Convert JSON string to BitSet
    /// Returns true on success, false on error
    mutating func fromJSON(_ jsonString: String, allowNew: Bool = false) -> Bool {
        guard let data = jsonString.data(using: .utf8) else { return false }
        do {
            let newBitset = try JSONDecoder().decode(BitSet.self, from: data)
            self.mask = newBitset.mask
            return true
        }
        catch {
            return false
        }
    }
    
    /// Convert BitSet to (optionally) formatted JSON string
    /// Returns JSON string or empty string on error
    func toJSON(prettyPrinted: Bool = true) -> String {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = prettyPrinted ? [.prettyPrinted] : []
            let s = try encoder.encode(self)
            return String(data: s, encoding: .utf8) ?? ""
        }
        catch {
            return ""
        }
    }
    
    /// Return true if BitSet contains specified bits. Shortcut for allSet()
    @inline(__always)
    static func == (lhs: BitSet, rhs: [T]) -> Bool {
        return lhs.allSet(rhs)
    }

    /// Compare BitSets. Return true if BitSets are equal
    @inline(__always)
    static func == (lhs: BitSet, rhs: BitSet) -> Bool {
        return lhs.mask == rhs.mask
    }

    /// Compare BitSets. Return true if BitSets are not equal
    @inline(__always)
    static func != (lhs: BitSet, rhs: BitSet) -> Bool {
        return lhs.mask != rhs.mask
    }
    
    /// Logical AND with bit
    /// Example: bitset = bitset & .bitname
    @inline(__always)
    static func & (lhs: BitSet, rhs: T) -> BitSet {
        let resultRawValue = lhs.mask & rhs.bitValue
        return BitSet(rawValue: resultRawValue)
    }
    
    /// Logical AND with bit
    /// Example: bitset = bitset & .bitname
    @inline(__always)
    static func &= (lhs: inout BitSet, rhs: T) {
        lhs.mask &= rhs.bitValue
    }

    /// Logical OR with bit
    /// Example: bitset = bitset | .bitname
    @inline(__always)
    static func | (lhs: BitSet, rhs: T) -> BitSet {
        let resultRawValue = lhs.mask | rhs.bitValue
        return BitSet(rawValue: resultRawValue)
    }
    
    /// Logical OR with bit
    /// Example: bitset = bitset | .bitname
    @inline(__always)
    static func |= (lhs: inout BitSet, rhs: T) {
        lhs.mask |= rhs.bitValue
    }
    
    /// Logical NOT
    @inline(__always)
    static prefix func ~ (lhs: BitSet) -> BitSet {
        return BitSet(rawValue: ~lhs.mask)
    }

}

