//
//  ParameterSet.swift
//
//  Part of Swift-Toolbox
//
//  Requires Castable, Dictionary Path, JEncodeDecode
//
//  Created by Dirk Braner on 24.11.24.
//

import Foundation

#if canImport(Numerics)

// Import Numerics for Complex<Double> support
import Numerics

#endif

//
// ParameterSet structure
//
// A ParameterSet can be used to manage application parameters.
//
// A ParameterSet contains 3 internal dictionaries of type [String: Any] for current,
// previous and initial parameter values.
//
// The internal dictionaries are of type <String, Any> (alias DictAny).
//
//   .current - Dictionary with current parameter values. When a parameter
//      value is changed via ParameterSet methods, the old value is stored in
//      dictionary .previous.
//      Warning: Change of parameter values by accessing this dictionary directly
//      won't be synchronized with .previous
//
//   .previous - Dictionary with previous parameter values. After initialization
//      of a parameterset values of .current and .previous are identical
//
//   .initial - Dictionary with initial values
//
// Important note:
//
//  *** The data type of an element (parameter) must be conform to protocol Castable! ***
//
// Methods:
//
//   reset(_ path: String?) - Reset a parameter or the whole parameterset
//      to it's initial value(s)
//
//   apply(_ path: String?) - Copy a parameter or the whole parameterset
//      from .current to .previous
//
//   undo(_ path: String?) - Copy a parameter or the whole parameter set
//      from .previous to .current
//
//   mergeSettings(_ initialValues: DictPar) - Add new parameters to parameterset.
//      New parameters are merged with dictionaries .current, .previous, .initial
//
//   addSetting(_ path: String, setting: T) - Add new parameter to parameterset.
//      Existing parameter is replaced by the new one.
//
//   addSetting(_ path: String, setting: DictAny) - Add new subdictionary to
//      parameterset. Existing parameter is replaced.
//
//   deleteSetting(_ path: String) - Delete a parameter from parameterset.
//
// Parameter values can be read or set by using subscript operator [].
//
// Reading parameter values
//
// Example:
//
//   let value: T = parameterSet[path: String, default: T? = nil]
//
// Reading a parameter value will never return nil. If no default value is
// specified (default is nil) and path exists but parameter doesn't exist, the
// initial value of a parameter is returned.
// If a parameter value is not castable to destination type, the default value
// is returned.
// If the path doesn't exist, the default value of the castable type is returned.
//
// Setting parameter values
//
// Example:
//
//   parameterSet[path: String] = newValue
//
// If an element exists and newValue is castable to the type of the element,
// newValue is assigned to the element. If newValue is not castable to the type
// of an existing element, nothing happens.
// If an element doesn't exist, assignment fails.
//

struct ParameterSet : Castable, Codable {
    
    //
    // Make ParameterSet conform to protocol Castable
    //
    
    // Default value is an empty parameterset
    static var defaultValue: ParameterSet { ParameterSet([:]) }
    
    /// Check if value is castable to ParameterSet
    static func isCastable<T>(from: T) -> Bool {
        return from is ParameterSet || from is DictAny
    }
    
    /// Cast to ParameterSet
    static func cast<T>(from: T) -> (any Castable) where T : Castable {
        switch from {
            case let v as ParameterSet: return v
            case let v as DictAny: return ParameterSet(v)
            default: return defaultValue
        }
    }
    
    /// Compare 2 parametersets
    static func == (lhs: ParameterSet, rhs: ParameterSet) -> Bool {
        let res = NSDictionary(dictionary: lhs.current).isEqual(to: NSDictionary(dictionary: rhs.current))
        return res
    }
    
    static func != (lhs: ParameterSet, rhs: ParameterSet) -> Bool {
        return !NSDictionary(dictionary: lhs.current).isEqual(to: NSDictionary(dictionary: rhs.current))
    }
    
    //
    // Make ParameterSet conform to protocol Codable. Needs JEncodeDecode
    //
    
    // List elements to be encoded / decoded
    enum CodingKeys : String, CodingKey {
        case current
    }
    
    /// Create and initialize a new ParameterSet object from JSON data
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: JSONCodingKeys.self)
        initial = try container.decode(DictAny.self)
        current = initial
        previous = initial
    }
    
    /// Encode to JSON data
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: JSONCodingKeys.self)
        try container.encode(current)
    }
    
    //
    // Implementation of ParameterSet
    //
    
    // Dictionaries containing parameter values
    var current: DictAny = [:]        // current values
    var previous: DictAny = [:]       // previous values
    var initial: DictAny = [:]        // initial values
    
    /// Convert parameters to JSON. Return empty string on error
    var jsonString: String { return toJSON(prettyPrinted: false) }
    
    /// Cast dictionary elements from specified dictionary to ParameterSet value types.
    /// Elements not existing in current ParameterSet are ignored
    mutating func cast(fromDict: DictAny, allowNew: Bool = false) {
        for (key, value) in fromDict {
            if initial.pathExists(key) {
                // If element exists, cast dictionary element to type of existing element
                if let d = value as? DictAny {
                    // Source value is of type DictAny
                    if var e = initial[key] as? DictAny {
                        // If destination element is a dictionary, cast dictionary-value to copy of existing dictionary
                        // Assign casted copy of dictionary to current element
                        e.cast(fromDict: d)
                        current[key] = e
                    }
                    else if var e = initial[key] as? ParameterSet {
                        // If destination element is a ParameterSet, cast dictionary-value to copy of existing ParameterSet
                        // Assign casted copy of ParameterSet to initial element
                        e.cast(fromDict: d)
                        current[key] = e
                    }
                    else if var e = initial[key] as? [Any] {
                        // Maybe this case never happens?
                        print("initial type is array [Any] \(key)")
                    }
                    else if var e = initial[key] as? [AnyObject] {
                        // Maybe this case never happens?
                        print("initial type is array [AnyObject] \(key)")
                    }
                    else {
                        print("Decode: Ignoring element \(key) with value \(value) type \(type(of: value))")
                    }
                }
                else if let a = value as? [Any], var e = initial[key] as? [Any] {
                    // Destination = Array, Source = Array
                    e.cast(fromArray: a)
                    current[key] = e
                }
                else if let v = value as? any Castable, let e = initial[key] as? any Castable, type(of: e).isCastable(from: v) {
                    // If existing element and source element are castable values, cast source to type of destination element
                    current[key] = type(of: e).cast(from: v)
                }
                else {
                    #if DEBUG
                    print("Decode: Element \(key) with value \(value) type \(type(of: value)) expected type \(String(describing: type(of: initial[key]!))) not handled by function \(#function)")
                    if let e = initial[key] as? any Castable {
                        print("initial key is castable from value? ", type(of: e).isCastable(from: value))
                        print("is value castable? ", value is any Castable, "\n")
                    }
                    #endif
                }
            }
            else if allowNew {
                print("Decode: Adding new element \(key) with value \(value)")
                initial[key] = value
                current[key] = value
                previous[key] = value
            }
            else {
                print("Decode: Path \(key) does not exist in initial dictionary. Adding new elements is not allowed (allowNew: false)")
            }
        }
    }
    
    // Convert parameterset to (optionally) formatted JSON
    func toJSON(prettyPrinted: Bool = true) -> String {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = prettyPrinted ? [.prettyPrinted] : []
            let s = try encoder.encode(self)
            return String(data: s, encoding: .utf8) ?? ""
        }
        catch {
            print(error)
            return ""
        }
    }
    
    /// Convert JSON string to parameterset (DictAny)
    /// Only JSON elements matching parameterset entries are stored in the parameterset1
    mutating func fromJSON(_ jsonString: String, allowNew: Bool = false) -> Bool {
        guard let data = jsonString.data(using: .utf8) else { return false }
        do {
            let newParameterset = try JSONDecoder().decode(ParameterSet.self, from: data)
            previous = current
            cast(fromDict: newParameterset.current, allowNew: allowNew)
            return true
        }
        catch {
            print(error)
            return false
        }
    }
    
    /// initialize parameter set with dictionaries of type DictAny
    init(_ initialSettings: DictAny = [:]) {
        current  = initialSettings
        previous = initialSettings
        initial  = initialSettings
    }
    
    /// initialize parameter set with dictionaries of type DictAny
    init(initialSettings: DictAny = [:], currentSettings: DictAny?, previousSettings: DictAny?) {
        current  = currentSettings ?? initialSettings
        previous = previousSettings ?? initialSettings
        initial  = initialSettings
    }
    
    /// initialize parameter set with JSON string
    init(_ jsonString: String) throws {
        guard let data = jsonString.data(using: .utf8) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Invalid JSON string"))
        }
        self = try JSONDecoder().decode(ParameterSet.self, from: data)
    }
    
    /// Add dictionary of type DictPar with new settings to parameter set
    mutating func mergeSettings(_ initialSettings: DictAny) {
        current.merge(initialSettings)  { (_, new) in new }
        previous.merge(initialSettings) { (_, new) in new }
        initial.merge(initialSettings)  { (_, new) in new }
    }
    
    
    /// Update parameterset with dictionary entries
    /// An existing value is updated if the new value is castable to the original type
    mutating func updateSettings(_ newSettings: DictAny) {
        for k in newSettings.keys {
            // Only castable values are allowed
            if let n = newSettings[k] as? (any Castable), let c = initial[k] as? (any Castable) {
                if current[k] != nil {
                    if type(of: c).isCastable(from: newSettings[k]) {
                        // Update existing parameters
                        previous[k] = current[k]
                        current[k] = type(of: c).cast(from: n)
                    }
                }
                else {
                    // Add new parameters
                    initial[k] = n
                    current[k] = n
                    previous[k] = n
                }
            }
        }
    }
    
    /// Add parameter of a castable type to parameter set
    mutating func addSetting<T: Castable>(_ path: String, _ setting: T) -> Bool {
        if !initial.pathExists(path) {
            initial[path: path]  = setting
            previous[path: path] = setting
            current[path: path]  = setting
            return true
        }
        return false
    }
    
    /// Add sub dictionary of type DictAny to parameter set
    mutating func addSetting(_ path: String, _ setting: DictAny) -> Bool {
        if !initial.pathExists(path) && isCastableDictionary(dict: setting) {
            initial[path: path]  = setting
            previous[path: path] = setting
            current[path: path]  = setting
            return true
        }
        return false
    }
    
    /// Delete parameter from parameter set
    mutating func deleteSetting(_ path: String) {
        current.delete(path)
        previous.delete(path)
        initial.delete(path)
    }
    
    /// Set parameter or parameter set to initial settings
    mutating func reset(_ path: String?) {
        if let path = path {
            current[path] = initial[path]
        }
        else {
            current = initial
        }
    }
    
    /// Set parameter or parameterset to previuos settings
    mutating func undo(_ path: String?) {
        if let path = path {
            current[path] = previous[path]
        }
        else {
            current = previous
        }
    }
    
    /// Set previous settings of parameter or parameterset to current settings
    mutating func apply(_ path: String?) {
        if let path = path {
            previous[path] = current[path]
        }
        else {
            previous = current
        }
    }

    /// Get or set parameter value identified by path string subscript
    subscript<T>(path: String, default def: T? = nil) -> T where T: Castable {
        get {
            let defValue: T = def ?? T.defaultValue

            if current.pathExists(path) {
                // Path exists => return current value
                // If element is a dictionary, convert it to a new(!) ParameterSet.
                // Note: Changes to this ParameterSet won't be synced with parent ParameterSet!
                if current[path] is DictAny {
                    return ParameterSet(initialSettings: initial[path] as! DictAny,
                                        currentSettings: current[path] as? DictAny,
                                        previousSettings: previous[path] as? DictAny) as! T
                }
                else {
                    return current[path: path, default: defValue]
                }
            }
            else {
                // Path doesn't exist => return initial value
                return initial[path: path, default: defValue]
            }
        }
        set {
            if current.pathExists(path) {
                // Path exists, save current value to previous dictionary
                previous[path: path] = current[path: path, default: T.defaultValue]
                current[path: path] = newValue
            }
            else if initial.pathExists(path) {
                current[path: path] = newValue
                previous[path: path] = newValue
            }
            else {
                // Assigning values is only allowed for existing elements
                return
            }
        }
    }
    
}

