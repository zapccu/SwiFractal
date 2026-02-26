//
//  based.swift
//  Swift-Toolbox
//
//  Created by Dirk Braner on 07.02.26.
//

import Foundation

/*
@attached(member, names: named(RawValue), named(rawValue), named(`init`), arbitrary)
@attached(extension, conformances: OptionSet)
public macro OptionSet<RawType>() =
        #externalMacro(module: "SwiftMacros", type: "OptionSetMacro")
*/

///
/// BitSet can be used to store values of a given enum as a bitmask.
/// The rawValue of the enum must be of type Int and must be conform to protocol CaseIterable.
///
/// Example:
///
///     enum EnumDrawingAttributes: Int, CaseIterable {
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

struct BitSet<Element>: ExpressibleByArrayLiteral, RawRepresentable, Codable
where Element: RawRepresentable, Element: CaseIterable, Element.RawValue == Int {
    
    // ----------------------------------------------------------------------
    //  Implementation of BitSet
    // ----------------------------------------------------------------------

	var rawValue: Int
    
    /// Return Array with all cases as String
    var allNames: [String] = Element.allCases.map { String(describing: $0) }
    
    /// Return number of highest bit, starting with 0
    var highBit: Int = Element.allCases.count - 1
    
    /// Return mask with all bits set
    var allBits: Int = (1 << (Element.allCases.count)) - 1
    
    /// Default initializer
	init() {
		rawValue = 0
	}
    
    /// Init with bit number. If bitnumber is > highest bit number or < 0, initialize with 0
    init (_ bit: Int) {
        self.rawValue = bit >= 0 && bit <= highBit ? 1 << bit : 0
    }
    
    /// Init with raw value without bit conversion. Bits > highBit are masked.
	init(rawValue: Int) {
		self.rawValue = rawValue & allBits
	}
    
    /// Init from String Array
    init(values: [String]) {
        self.rawValue = 0
        for value in values {
            if let bit = allNames.firstIndex(of: value) {
                self.rawValue |= 1 << bit
            }
        }
    }

    /// Initialize bitset with multiple bits by using a bitwise OR operation
    /// Example: bitset = [.bit1, .bit2 ]
    /// This function is also called for decoding keyed JSON strings like "{ \"key\": [ \"case1\”, \"case2\" ] }"
    init(arrayLiteral elements: Element...) {
        let or = elements.reduce(0) { $0 | 1 << $1.rawValue }
        self.rawValue = or
    }
    
    /// Returns name of bit as String
    func bitName(_ bit: Element) -> String {
        return String(describing: bit)
    }

    /// Test if all bits in array are set
    func allSet(_ bits: [Element]) -> Bool {
        return bits.allSatisfy( { self.rawValue & (1 << $0.rawValue) != 0} )
    }
    
    /// Test if any bit in array is set
    func anySet(_ bits: [Element]) -> Bool {
        return bits.contains(where: { self.rawValue & (1 << $0.rawValue) != 0} )
    }
    
    // ----------------------------------------------------------------------
    //  JSON encoding / decoding
    // ----------------------------------------------------------------------

    /// Put bitset bit-names as String array into JSON instead of rawValue
    func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()
        let names = Element.allCases.filter { self.rawValue & (1 << $0.rawValue) != 0 }.map { String(describing: $0) }
        try container.encode(contentsOf: names)
    }
    
    /// Decode from JSON array
    /// This function is called for keyless JSON arrays like "[ \"case1\", \"case2\" ]"
    init(from decoder: Decoder) throws {
        // Open an unkeyedContainer for reading the array
        var container = try decoder.unkeyedContainer()
        self.rawValue = 0

        // Iterate through the array
        while !container.isAtEnd {
            let value = try container.decode(String.self)
            if let bit = allNames.firstIndex(of: value) {
                self.rawValue |= 1 << bit
            }
        }
    }
    
    /// Convert JSON string to BitSet
    /// Returns true on success, false on error
    mutating func fromJSON(_ jsonString: String, allowNew: Bool = false) -> Bool {
        guard let data = jsonString.data(using: .utf8) else { return false }
        do {
            let newBitset = try JSONDecoder().decode(BitSet.self, from: data)
            self.rawValue = newBitset.rawValue
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

    // ----------------------------------------------------------------------
    //  Logical operations
    // ----------------------------------------------------------------------

    /// Logical AND with bit
    /// Example: bitset = bitset & .bitname
    static func & (lhs: BitSet, rhs: Element) -> BitSet {
        let bitMask = 1 << rhs.rawValue
        let resultRawValue = lhs.rawValue & bitMask
        return BitSet(rawValue: resultRawValue)
    }
    
    /// Logical AND with bit
    /// Example: bitset = bitset & .bitname
    static func &= (lhs: inout BitSet, rhs: Element) {
        let bitMask = 1 << rhs.rawValue
        lhs.rawValue &= bitMask
    }

    /// Logical OR with bit
    /// Example: bitset = bitset | .bitname
    static func | (lhs: BitSet, rhs: Element) -> BitSet {
        let bitMask = 1 << rhs.rawValue
        let resultRawValue = lhs.rawValue | bitMask
        return BitSet(rawValue: resultRawValue)
    }
    
    /// Logical OR with bit
    /// Example: bitset = bitset | .bitname
    static func |= (lhs: inout BitSet, rhs: Element) {
        let bitMask = 1 << rhs.rawValue
        lhs.rawValue |= bitMask
    }
    
    /// Conditional statements with logical AND
    /// Example: if bitset & .bitname ...
    static func & (lhs: BitSet, rhs: Element) -> Bool {
        let bitMask = 1 << rhs.rawValue
        return (lhs.rawValue & bitMask) != 0
    }
    
    /// Conditional statements with logical OR
    /// Example: if bitset | .bitname ...
    static func | (lhs: BitSet, rhs: Element) -> Bool {
        let bitMask = 1 << rhs.rawValue
        return (lhs.rawValue | bitMask) != 0
    }

}

