//
//  DictionaryPath.swift
//  Swift-Toolbox
//
//  Created by Dirk Braner on 24.11.24.
//

//
// Extend Dictionaries of type <String,Any> to support direct access to
// dictionary hierarchies by specifying a path.
//
// A path is a string where the segments (representing the dictionary levels) are
// seperated by a ".". In a dictionary subscript a path must be specified with
// label 'path'.
//
// Operator == is overloaded and can be used to compare two dictionaries of type
// DictAny.
//
// Example:
//
//   var myDict = [
//      "a": 1,
//      "b": 2,
//      "c:" [
//         "d:" Int(3),
//         "e": 1.5
//      ]
//
//   let a = myDict[path: "a"] as? Int ?? 0
//   let d = myDict[path: "c.d", default: 0] as? Int ?? 0
//   let e = myDict[path: "c.e", default: 0.0] as? Double ?? 0.0
//
//   myDict[path: "c.d"] = 10
//   myDict[path: "c.d"] = 10.0        // Type is changed to Double
//
//   myDict[path: "x.y"] = Int(300)    // Add new subdictionary x with element y
//
//   myDict[path: "c.d"] = nil         // Delete element d in subdictionary c
//

import Foundation

/// Alias for dictionary of type [String: Any]
typealias DictAny = [String: Any]

/// Compare 2 dictionaries
func == (lhs: DictAny, rhs: DictAny) -> Bool {
    return NSDictionary(dictionary: lhs).isEqual(to: NSDictionary(dictionary: rhs))
}

extension Dictionary where Key == String {
      
    /// Check if path exists
    func pathExists(_ path: String) -> Bool {
        let segs = path.components(separatedBy: ".")
        
        guard segs.count > 0 && segs[0] != "" else { return false }

        if segs.count == 1 {
            // Reached last segment
            return self.keys.contains(Key(segs[0]))
        }
        else if let subDict = self[segs[0]] as? DictAny {
            // Current element is sub-dictionary. Recursively call function with remaining path
            let newPath = segs.dropFirst().joined(separator: ".")
            return subDict.pathExists(newPath)
        }
        
        return false
    }
    
    /// Get or set value of type Any identified by parameter keyPath
    ///
    /// Getting a value returns ...
    ///    ... nil if element doesn't exist and no default is specified
    ///    ... the dictionary if path is an empty string
    ///
    /// Setting a value fails if type of a sub-dictionary element is not DictAny
    /// If newValue is nil, an existing element is deleted
    ///
    subscript(path keyPath: String, default def: Any? = nil) -> Any? {
        get {
            let segs = keyPath.components(separatedBy: ".")
            
            // If key is empty return dictionary
            guard segs.count > 0 && segs[0] != "" else { return self }
            
            let key = Key(segs[0])
            
            if segs.count == 1 {
                // Reached last segment in path
                if self.keys.contains(key) {
                    return self[key]
                }
            }
            else if let subDict = self[key] as? DictAny {
                // Recursively access sub-dictionary
                let newPath = segs.dropFirst().joined(separator: ".")
                return subDict[path: newPath, default: def]
            }

            return def
        }
        set {
            let segs = keyPath.components(separatedBy: ".")
            
            // Prevent an empty key
            guard segs.count > 0 && segs[0] != "" else { return }
            
            let key = Key(segs[0])
            
            if segs.count == 1 {
                // Reached last segment in path
                if newValue == nil {
                    // Delete element
                    self[key] = nil
                }
                else if newValue is Value {
                    // Assign value
                    self[key] = (newValue! as! Value)
                }
            }
            else {
                // Handle sub-dictionaries
                let newPath = segs.dropFirst().joined(separator: ".")
                
                if self.keys.contains(key) {
                    // Element exists
                    if var subDict = self[key] as? DictAny {
                        // Element exists and is a sub-dictionary
                        // Recursively assign value to sub-dictionary element
                        subDict[path: newPath] = newValue
                        self[key] = (subDict as! Value)
                    }
                    else {
                        // Element exists, but is not a dictionary
                        // Do nothing
                        return
                    }
                }
                else {
                    // Element doesn't exist. Create a new sub-dictionary
                    // Recursively assign value to sub-dictionary element
                    var subDict: [Key: Any] = [:]
                    subDict[path: newPath] = newValue
                    self[key] = (subDict as! Value)
                }
            }
        }
    }

}
