//
//  Castable.swift
//
//  Implementation of protocols Castable and CastableEnum
//
//  Created by Dirk Braner on 25.01.25.
//

import Foundation

#if canImport(Numerics)

// Import Numerics for Complex<Double> support
import Numerics

#endif

// --------------------------------------------------------
//  Protocol for castable types.
//  Castable is conform to protocols Equatable and Any.
// --------------------------------------------------------

protocol Castable: Equatable, Any {
    
    /// Check if value of type T is castable to current value type
    ///
    /// Examples:
    ///
    ///   Int.isCastable(from: 5.0) => Returns true
    ///   Int.isCastable(from: "xy") => Returns false
    ///   Int.isCastable(from: "2") => Returns true
    ///
    static func isCastable<T>(from: T) -> Bool

    /// Cast a numeric value from type T to a type conform to protocol Castable
    /// If casting is not possible, defaultValue must be returned
    ///
    /// Examples:
    ///
    ///    let x: Int = Int.cast(from: 2.5) => x = 2
    ///    let x: Int = Int.cast(from: "y") => x = 0 = default value of type Int
    ///
    static func cast<T>(from: T) -> (any Castable) where T: Castable
    
    /// Value to be returned if a value is not castable
    /// A numeric type should return zero
    ///
    static var defaultValue: Self { get }
    
}


// --------------------------------------------------------
//  Extended protocol for castable Enum with Int raw value
//  Conform to protocols Castable and RawRepresentable
// --------------------------------------------------------

protocol CastableEnum : Castable, RawRepresentable {
    
    /// Return array with allowed raw values
    static var values: [Int] { get }
    
    // Return array with alias names of allowed raw values
    static var names: [String] { get }
    
}


// --------------------------------------------------------
//  Make Bool, Int, UInt, Float, Double and String conform
//  to protocol Castable by implementing
//
//    defaultValue { get }
//    isCastable()
//    cast()
//
//  If package Numerics is added to the target, also type
//  Complex<Double> is made conform to Castable.
// --------------------------------------------------------

extension Bool: Castable {
    
    static var defaultValue: Bool { false }
    
    static func isCastable<T>(from: T) -> Bool {
        switch from {
            case _ as Bool:   return true
            case _ as Int:    return true
            case _ as UInt:   return true
            case let v as String: return ["true", "false", "1", "0"].contains(v.lowercased()) ? true : false
            default:              return false
        }
    }
    
    static func cast<T>(from: T) -> (any Castable) where T : Castable {
        switch(from) {
            case let v as Bool:    return v
            case let v as Int:     return v != 0 ? true : false
            case let v as UInt:    return v != 0 ? true : false
            case let v as String:  return ["true", "1"].contains(v.lowercased()) ? true : defaultValue
            default: return defaultValue
        }
    }
}

extension Int: Castable {
    
    static var defaultValue: Int { 0 }
    
    static func isCastable<T>(from: T) -> Bool {
        return from is Bool || from is Int || from is UInt || from is Float || from is Double || (from is String && Double(from as! String) != nil)
    }
    
    static func cast<T>(from: T) -> (any Castable) where T : Castable {
        switch from {
            case let v as Int:    return v
            case let v as Bool:   return v ? 1 : 0
            case let v as UInt:   return Int(v)
            case let v as Float:  return Int(v)
            case let v as Double: return Int(v)
            case let v as String where Double(v) != nil: return Int(Double(v)!)
            default: return defaultValue
        }
    }
}

extension UInt: Castable {
    
    static var defaultValue: UInt { 0 }

    static func isCastable<T>(from: T) -> Bool {
        return from is Bool || from is UInt || from is Int || from is Float || from is Double || (from is String && Double(from as! String) != nil)
    }
    
    static func cast<T>(from: T) -> (any Castable) where T : Castable {
        switch from {
            case let v as UInt:   return v
            case let v as Bool:   return v ? 1 : 0
            case let v as Int:    return UInt(v)
            case let v as Float:  return UInt(v)
            case let v as Double: return UInt(v)
            case let v as String where Double(v) != nil: return UInt(Double(v)!)
            default: return defaultValue
        }
    }
}

extension Float: Castable {
    
    static var defaultValue: Float { Float(0.0) }

    static func isCastable<T>(from: T) -> Bool {
        return from is UInt || from is Int || from is Float || from is Double || (from is String && Double(from as! String) != nil)
    }
    
    static func cast<T>(from: T) -> (any Castable) where T : Castable {
        switch from {
            case let v as Float:  return v
            case let v as Int:    return Float(v)
            case let v as UInt:   return Float(v)
            case let v as Double: return Float(v)
            case let v as String where Double(v) != nil: return Float(Double(v)!)
            default: return defaultValue
        }
    }
}

extension Double: Castable {
    
    static var defaultValue: Double { Double(0.0) }

    #if canImport(Numerics)
    static func isCastable<T>(from: T) -> Bool {
        return from is UInt || from is Int || from is Float || from is Double || from is Complex<Double> ||
            (from is String && Double(from as! String) != nil)
    }
    #else
    static func isCastable<T>(from: T) -> Bool {
        return from is UInt || from is Int || from is Float || from is Double || (from is String && Double(from as! String) != nil)
    }
    #endif
    
    static func cast<T>(from: T) -> (any Castable) where T : Castable {
        switch from {
            case let v as Double: return v
            case let v as Int:    return Double(v)
            case let v as UInt:   return Double(v)
            case let v as Float:  return Double(v)
            case let v as String where Double(v) != nil: return Double(v)!
            #if canImport(Numerics)
            case let v as Complex<Double>: return v.real
            #endif
            default: return defaultValue
        }
    }
}

extension String: Castable {
    
    static var defaultValue: String { return "" }
    
    static func isCastable<T>(from: T) -> Bool {
        return from is Bool || from is UInt || from is Int || from is Float || from is Double || from is String
    }
    
    static func cast<T>(from: T) -> (any Castable) where T : Castable {
        switch from {
            case let v as String: return v
            case let v as Bool:   return v ? "true" : "false"
            case let v as Int:    return String(v)
            case let v as UInt:   return String(v)
            case let v as Float:  return String(v)
            case let v as Double: return String(v)
            default: return defaultValue
        }
    }
}

// Make BitSet conform to protocol Castable
extension BitSet: Castable  {
    
    static func isCastable<T>(from: T) -> Bool {
        return from is Int || from is String || from is Array<String> || from is Array<Any> || from is BitSet<Element>
    }
    
    static func cast<T>(from: T) -> any Castable where T : Castable {
        if let v = from as? BitSet<Element> {
            return BitSet<Element>(rawValue: v.rawValue)
        }
        else if from is Int {
            return BitSet<Element>(rawValue: from as! Int)
        }
        else if from is String {
            return BitSet<Element>(values: [from as! String])
        }
        else if from is Array<String> {
            return BitSet<Element>(values: from as! [String])
        }
        else if from is Array<Any> {
            var values: [String] = []
            for value in from as! [Any] {
                if let stringValue = value as? String {
                    values.append(stringValue)
                }
            }
            return BitSet<Element>(values: values)
        }
        else {
            return defaultValue
        }
    }
    
    static var defaultValue: BitSet<Element> { BitSet<Element>() }
}

// Make Options conform to protocol Castable
extension Options: Castable  {
    
    static func isCastable<T>(from: T) -> Bool {
        return from is Int || from is String || from is Options<Element>
    }

    mutating func cast<T>(from: T) where T : Castable {
        if let v = T.cast(from: from) as? Options<Element> {
            self.rawValue = v.rawValue
        }
        else {
            self.rawValue = 0
        }
    }

    static func cast<T>(from: T) -> any Castable where T : Castable {
        if let v = from as? Options<Element> {
            return Options<Element>(rawValue: v.rawValue)
        }
        else if let v = from as? Int {
            return Options<Element>(rawValue: v)
        }
        else if let v = from as? String {
            return Options<Element>(value: v)
        }
        else {
            return defaultValue
        }
    }
    
    static var defaultValue: Options<Element> { Options<Element>() }
}

#if canImport(Numerics)

// Complex Numbers are supported if package Numerics is added as a dependency

extension Complex<Double>: Castable {
    
    static var defaultValue: Complex<Double> { Complex<Double>(0, 0) }
    
    static func isCastable<T>(from: T) -> Bool {
        if let a = from as? [Any] { return a.count == 2 && a.allSatisfy({ $0 is Double }) }
        return from is Bool || from is Int || from is UInt || from is Float || from is Double || from is Complex<Double> ||
             (from is String && parseComplex(from as! String) != nil)
    }
    
    static func cast<T>(from: T) -> (any Castable) where T : Castable {
        switch from {
            case let v as Complex<Double>: return v
            case let v as Int:    return Complex<Double>(Double(v), 0)
            case let v as Bool:   return v ? Complex<Double>(1, 0) : Complex<Double>(0, 0)
            case let v as UInt:   return Complex<Double>(Double(v), 0)
            case let v as Float:  return Complex<Double>(Double(v), 0)
            case let v as Double: return Complex<Double>(v, 0)
            case let v as [Double]: return v.count > 0 ? Complex<Double>(v[0], v.count > 1 ? v[1] : 0.0) : Complex<Double>(0.0, 0.0)
            case let v as String: return parseComplex(v) ?? defaultValue
            default: return defaultValue
        }
    }
    
    /// Parse complex number string
    static func parseComplex(_ input: String) -> Complex<Double>? {
        // Regex matches: (Real Part) (Sign) [(Imaginary Part)] i
        // Examples:
        // "3.5+4.2i" -> Complex<Double>(3.5, 4.2)
        // "3.5-i" -> Complex<Double>(3.5, -1.0)
        let regex = /([+-]?\d*\.?\d+)([+-])(\d*\.?\d+)i/
        
        guard let match = input.firstMatch(of: regex) else { return nil }
        guard let real = Double(match.1) else { return nil }
        guard let imagValue = match.3.isEmpty ? 1.0 : Double(match.3) else { return nil }
        
        return match.2 == "-" ? Complex(real, -imagValue) : Complex(real, imagValue)
    }
}

#endif


// --------------------------------------------------------
//  Helper functions
// --------------------------------------------------------

/// Compare two castable values
///
/// If types are different, value on right hand side is casted to type
/// of left hand side value before comparing the values.
/// For exact matching without casting use operator == which is implemented
/// in DictionaryPath.
///
func compare<L,R>(_ lhs: L, _ rhs: R) -> Bool where L: Castable, R: Castable {
    return L.isCastable(from: rhs) ? L.cast(from: rhs) as! L == lhs : false
}

/// Check if all array elements are castable
func isCastableArray<T>(_ array: [T]) -> Bool {
    return array.allSatisfy({ $0 is (any Castable) })
}

/// Check if all elements of dictionary are castable
func isCastableDictionary<K, V>(dict: [K: V]) -> Bool {
    return dict.values.allSatisfy ({ $0 is (any Castable) })
}

/// Check if value is castable to a CastableEnum
func isCastableToEnum<E,T>(enumType: E.Type, from: T) -> Bool where E: CastableEnum {
    if from is E { return true }
    if Int.isCastable(from: from), let v = from as? any Castable {
        return E.values.contains(Int.cast(from: v) as! Int)
    }
    else if E.names.count > 0, from is String {
        return E.names.contains(from as! String)
    }
    return false
}

/// Cast value to a CastableEnum
func castToEnum<E,T>(enumType: E.Type, from: T) -> E where E: CastableEnum {
    if from is E { return from as! E }
    if let v = from as? any Castable, Int.isCastable(from: v) {
        return E(rawValue: Int.cast(from: v) as! E.RawValue) ?? E.defaultValue
    }
    else if E.names.count > 0, from is String {
        return E(rawValue: (E.names.firstIndex(of: from as! String) ?? 0) as! E.RawValue) ?? E.defaultValue
    }
    return E.defaultValue
}


// --------------------------------------------------------
//  Extend Dictionary to support Castable element values
// --------------------------------------------------------

extension Dictionary where Key == String {
    
    /// Delete a dictionary element
    mutating func delete(_ path: String) {
        if pathExists(path) {
            self[path: path] = nil
        }
    }
    
    /// Cast dictionary elements from specified dictionary
    mutating func cast(fromDict: DictAny) {
        for (key, value) in fromDict {
            if keys.contains(key) {
                // Element exists
                if let d = value as? DictAny, var e = self[key] as? DictAny {
                    // If existing element is a dictionary, recursively call cast()
                    e.cast(fromDict: d)
                    self[key] = (e as! Value)
                }
                else if let v = value as? any Castable, let e = self[key] as? any Castable, type(of: e).isCastable(from: v) {
                    // If existing element and source element are castable values, cast source to destination element
                    self[key] = (type(of: e).cast(from: v) as! Value)
                }
            }
            else {
                // Element doesn't exist. Create new element
                self[key] = (value as! Value)
            }
        }
    }
    
    /// Get or set dictionary of type [String: Any]
    subscript(path path: String, default def: DictAny = [:]) -> DictAny {
        get {
            guard let v = self[path] as? DictAny else { return def }
            return v
        }
        set {
            self[path] = (newValue as! Value)
        }
    }
    
    /// Get or set a castable value identified by parameter path
    ///
    /// Getting a value for a non existing element returns ...
    ///    ... default value if parameter default is specified
    ///    ... T.defaultValue if no default value is specified
    ///
    /// Getting a value for an existing but not castable element returns T.default
    ///
    /// Setting a value fails if ...
    ///    ... path addresses sub-dictionaries and type of a path segment is not DictAny
    ///    ... element exists but new value cannot be casted to type of existing element
    ///
    /// When setting a value for non-existing sub-dictionaries or elements, sub-dictionaries
    /// and elements are created.
    ///
    subscript<T>(path path: String, default def: T = T.defaultValue) -> T where T: Castable {
        get {
            // Split path into segments
            let segs = path.components(separatedBy: ".")
            
            // Prevent an empty key
            guard segs.count > 0 && segs[0] != "" && self.keys.contains(segs[0]) else { return def }
            
            let key = Key(segs[0])
            
            if segs.count == 1 {
                // Reached last element in path
                if let v = self[key] as? any Castable, T.isCastable(from: v) {
                    // Cast element value to desired type
                    return T.cast(from: v) as! T
                }
            }
            else if let subDict = self[key] as? DictAny {
                // Current element is a (sub-)dictionary of type [String: Any]
                let newPath = segs.dropFirst().joined(separator: ".")
                // return subDict.getValue(path: newPath, default: def)
                return subDict[path: newPath, default: def]
            }

            // In any other case return default value
            return def
        }
        set {
            // Split path into segments
            let segs = path.components(separatedBy: ".")
            
            // Prevent an empty key
            guard segs.count > 0 && segs[0] != "" else { return }
            
            let key = Key(segs[0])
            
            if segs.count == 1 {
                // Reached last element in path
                if self.keys.contains(key) {
                    if let v = self[path] as? any Castable, type(of: v).isCastable(from: newValue) {
                        // Element exists and new value is castable
                        // Cast new value to type of existing element
                        let t = type(of: v)
                        self[key] = (t.cast(from: newValue) as! Value)
                    }
                }
                else {
                    // Element doesn't exist. Add element to dictionary
                    self[key] = (newValue as! Value)
                }
            }
            else {
                let newPath = segs.dropFirst().joined(separator: ".")
                
                if self.keys.contains(key) {
                    // Element exists
                    if var subDict = self[key] as? DictAny {
                        // Element is a (sub-)dictionary of type [String: Any]
                        subDict[path: newPath] = newValue
                        self[key] = (subDict as! Value)
                    }
                }
                else {
                    // Element does not exist. Create sub-dictionary and assign value
                    var subDict: [Key: Any] = [:]
                    subDict[path: newPath] = newValue
                    self[key] = (subDict as! Value)
                }
            }
        }
    }
    
}


// --------------------------------------------------------
//  Extend Array to support Castable element values
// --------------------------------------------------------

extension Array where Element: Any {
    
    mutating func cast(fromArray: [Any]) {
        guard fromArray.count == self.count else { return }

        for i in 0..<self.count {
            if let e = self[i] as? any Castable, let v = fromArray[i] as? any Castable, type(of: e).isCastable(from: v) {
                self[i] = type(of: e).cast(from: v) as! Element
            }
        }
    }
}
