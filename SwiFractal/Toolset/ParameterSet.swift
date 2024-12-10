//
//  ParameterSet.swift
//  Swift-Toolbox
//
//  Created by Dirk Braner on 24.11.24.
//
//  Requires DictionaryPath
//

enum AccessMode: Int {
    case current = 0
    case previous = 1
    case initial = 2
}

struct ParameterSet {
    static let current: Int = 0
    static let previous: Int = 1
    static let initial: Int = 2
    
    static let numSettings: Int = 3
    
    /// Array with dictionaries "current", "previous", "initial"
    var settings: [DictPar]
    
    /// Initialize parameter set with dictionary of type DictPar = <String>,<Any>
    init(_ initialSettings: DictPar = [:]) {
        settings = Array(repeating: initialSettings, count: ParameterSet.numSettings)
    }
 
    /// Update existing setting values, add new setting values
    mutating func updateSettings(_ newSettings: DictPar) {
        for k in newSettings.keys {
            if settings[ParameterSet.current][k] != nil {
                // Update existing parameters
                settings[ParameterSet.previous][k] = settings[ParameterSet.current][k]
                settings[ParameterSet.current][k] = newSettings[k]
            }
            else {
                // Add new parameters
                settings[ParameterSet.initial][k] = newSettings[k]
                settings[ParameterSet.current][k] = newSettings[k]
                settings[ParameterSet.previous][k] = newSettings[k]
            }
        }
    }
    
    /// Add only non existing parameters to settings
    mutating func addSettings(_ newSettings: DictPar) {
        guard !newSettings.isEmpty else { return }
        
        for k in newSettings.keys {
            if settings[ParameterSet.initial][k] == nil {
                // Add new parameters
                settings[ParameterSet.initial][k] = newSettings[k]
                settings[ParameterSet.current][k] = newSettings[k]
                settings[ParameterSet.previous][k] = newSettings[k]
            }
        }
    }
    
    /// Set parameter or parameter set to initial settings
    mutating func reset(_ path: String?) {
        if let path = path {
            settings[ParameterSet.current][path] = settings[ParameterSet.initial][path]
        }
        else {
            settings[ParameterSet.current] = settings[ParameterSet.initial]
        }
    }
    
    /// Set parameter or parameterset to previuos settings
    mutating func undo(_ path: String?) {
        if let path = path {
            settings[ParameterSet.current][path] = settings[ParameterSet.previous][path]
        }
        else {
            settings[ParameterSet.current] = settings[ParameterSet.previous]
        }
    }
    
    /// Set previous settings of parameter or parameterset to current settings
    mutating func apply(_ path: String?) {
        if let path = path {
            settings[ParameterSet.previous][path] = settings[ParameterSet.current][path]
        }
        else {
            settings[ParameterSet.previous] = settings[ParameterSet.current]
        }
    }
        
    /// Get parameter value identified by path string
    func get(_ path: String, _ defaultValue: Any? = nil, _ mode: AccessMode = .current) -> Any? {
        return settings[mode.rawValue][path, defaultValue]
    }

    /// Get or set parameter value identified by path string subscript
    subscript<T>(_ path: String, _ defaultValue: T? = nil) -> T {
        get {
            return get(path, defaultValue, .current) as! T
        }
        set {
            settings[ParameterSet.previous][path] = settings[ParameterSet.current][path]
            settings[ParameterSet.current][path] = newValue
        }
    }

}
