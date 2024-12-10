//
//  Bitfield.swift
//  SwiFractal
//
//  Created by Dirk Braner on 28.11.24.
//

struct Bitfield<T>: ExpressibleByIntegerLiteral {
    
    typealias IntegerLiteralType = UInt
    
    var rawValue: UInt
    
    /// Initialize Bitfield value with unsigned integer value
    init(_ value: UInt = 0) {
        self.rawValue = value
    }

    /// Initialize Bitfield value with unsigned integer literal
    init(integerLiteral value: UInt) {
        self.rawValue = value
    }

    /// Compare Bitfield values
    static func == (lhs: Bitfield<T>, rhs: Bitfield<T>) -> Bool {
        lhs.rawValue == rhs.rawValue
    }
    
    /// Compare Bitfield values
    static func != (lhs: Bitfield<T>, rhs: Bitfield<T>) -> Bool {
        !(lhs == rhs)
    }
    
    /// Negate Bitfield value
    static prefix func ~ (lhs: Bitfield<T>) -> Bitfield<T> {
        Bitfield<T>(~lhs.rawValue)
    }
    
    /// Bitfield OR
    static func | (lhs: Bitfield<T>, rhs: Bitfield<T>) -> Bitfield<T> {
        Bitfield<T>(lhs.rawValue | rhs.rawValue)
    }
    
    static func |= (lhs: inout Bitfield<T>, rhs: Bitfield<T>) {
        lhs.rawValue |= rhs.rawValue
    }
    
    /// Bitfield AND
    static func & (lhs: Bitfield<T>, rhs: Bitfield<T>) -> Bitfield<T> {
        Bitfield<T>(lhs.rawValue & rhs.rawValue)
    }
    
    /// Bitfield XOR
    static func ^ (lhs: Bitfield<T>, rhs: Bitfield<T>) -> Bitfield<T> {
        Bitfield<T>(lhs.rawValue ^ rhs.rawValue)
    }
    
    /// Bits shift left
    static func << (lhs: Bitfield<T>, rhs: Int) -> Bitfield<T> {
        Bitfield<T>(lhs.rawValue << rhs)
    }
    
    /// Bits shift right
    static func >> (lhs: Bitfield<T>, rhs: Int) -> Bitfield<T> {
        Bitfield<T>(lhs.rawValue >> rhs)
    }
    
    /// Logical AND
    static func && (lhs: Bitfield<T>, rhs: Bitfield<T>) -> Bool {
        lhs.rawValue & rhs.rawValue != 0
    }
    
    /// Logical OR
    static func || (lhs: Bitfield<T>, rhs: Bitfield<T>) -> Bool {
        lhs.rawValue | rhs.rawValue != 0
    }
}

extension Bitfield where T: RawRepresentable {
    init(_ value: T) {
        self.init(value.rawValue as! UInt)
    }
}


