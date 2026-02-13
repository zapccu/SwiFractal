//
//  JEncodeDecode.swift
//
//  Encoding / decoding of Dictionary[String: Any] and Array[Any] types
//
//  Created by Dirk Braner on 07.02.25.
//
//  Adapted from:
//
//  Original: https://gist.github.com/loudmouth/332e8d89d8de2c1eaf81875cfcd22e24
//  Adds encoding: https://github.com/3D4Medical/glTFSceneKit/blob/master/Sources/glTFSceneKit/GLTF/JSONCodingKeys.swift
//  Adds fix for null inside arrays causing infinite loop: https://gist.github.com/loudmouth/332e8d89d8de2c1eaf81875cfcd22e24#gistcomment-2807855
//

#if canImport(Numerics)

// Import Numerics for Complex<Double> support
import Numerics

/*
extension Complex<Double> {

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        // Check if the array has exactly 2 elements
        guard container.count == 2 else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected array with exactly 2 elements, but found \(container.count ?? 0)."
                )
            )
        }
        
        // Proceed with decoding if count is correct
        let r = try container.decode(Double.self)
        let i = try container.decode(Double.self)
        self.init(r, i)
    }
}
*/
#endif

/*
struct ComplexWrapper: Codable {
    let value: Complex<Double>

    enum CodingKeys: String, CodingKey {
        case real, imaginary
    }

    init(_ value: Complex<Double>) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let real = try container.decode(Double.self, forKey: .real)
        let imaginary = try container.decode(Double.self, forKey: .imaginary)
        self.value = Complex(real, imaginary)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(value.real, forKey: .real)
        try container.encode(value.imaginary, forKey: .imaginary)
    }
}

func cplxJSON () {
    // 1. Define a complex number
    let originalComplex = Complex(1.5, -2.0)
    let wrapper = ComplexWrapper(originalComplex)
    
    // 2. Encode to JSON
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted // For readable output
    
    do {
        let jsonData = try encoder.encode(wrapper)
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print("Encoded JSON:\n\(jsonString)")
        }
        
        // 3. Decode from JSON
        let decoder = JSONDecoder()
        let decodedWrapper = try decoder.decode(ComplexWrapper.self, from: jsonData)
        
        let result = decodedWrapper.value
        print("\nDecoded Complex Number: \(result.real) + \(result.imaginary)i")
        
    } catch {
        print("Error during encoding/decoding: \(error)")
    }
}
*/

// --------------------------------------------------------
//  JSONCodingKeys
// --------------------------------------------------------

struct JSONCodingKeys: CodingKey {
    var stringValue: String
    
    init(stringValue: String) {
        self.stringValue = stringValue
    }
    
    var intValue: Int?
    
    init?(intValue: Int) {
        self.init(stringValue: "\(intValue)")
        self.intValue = intValue
    }
}

// --------------------------------------------------------
//  Decoding
// --------------------------------------------------------

//
// Extend KeyedDecodingContainer (dictionaries)
//

extension KeyedDecodingContainer {
    
    func decode(_ type: [String: Any].Type, forKey key: K) throws -> [String: Any] {
        let container = try self.nestedContainer(keyedBy: JSONCodingKeys.self, forKey: key)
        return try container.decode(type)
    }
    
    func decode(_ type: [Any].Type, forKey key: K) throws -> [Any] {
        var container = try self.nestedUnkeyedContainer(forKey: key)
        return try container.decode(type)
    }
    
    func decode(_ type: [String: Any].Type) throws -> [String: Any] {
        var dictionary = [String: Any]()
        
        for key in allKeys {
            if let boolValue = try? decode(Bool.self, forKey: key) {
                dictionary[key.stringValue] = boolValue
            }
            else if let stringValue = try? decode(String.self, forKey: key) {
                dictionary[key.stringValue] = stringValue
            }
            else if let intValue = try? decode(Int.self, forKey: key) {
                dictionary[key.stringValue] = intValue
            }
            else if let doubleValue = try? decode(Double.self, forKey: key) {
                dictionary[key.stringValue] = doubleValue
            }
            else if let nestedDictionary = try? decode([String: Any].self, forKey: key) {
                dictionary[key.stringValue] = nestedDictionary
            }
            else if let nestedArray = try? decode([Any].self, forKey: key) {
                dictionary[key.stringValue] = nestedArray
            }
            else if let intArray = try? decode([Int].self, forKey: key) {
                dictionary[key.stringValue] = intArray
            }
            else if let doubleArray = try? decode([Double].self, forKey: key) {
                dictionary[key.stringValue] = doubleArray
            }
            else if let stringArray = try? decode([String].self, forKey: key) {
                dictionary[key.stringValue] = stringArray
            }
            else {
                print("KeyedDecodingContainer.decode: Unsupported JSON type for key \(key)")
                throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Unsupported JSON type found for \(key)"))
            }
        }
        
        return dictionary
    }
}

//
// Extend UnkeyedDecondigContainer (arrays)
//

extension UnkeyedDecodingContainer {
    mutating func decode(_ type: [Any].Type) throws -> [Any] {
        var array: [Any] = []
        
        while isAtEnd == false {
            // let value: String? = try decode(String?.self)
            // guard value != nil else { continue }

            if let value = try? decode(Bool.self) {
                array.append(value)
            }
            else if let value = try? decode(Int.self) {
                array.append(value)
            }
            else if let value = try? decode(Double.self) {
                array.append(value)
            }
            else if let value = try? decode(String.self) {
                array.append(value)
            }
            else if let nestedDictionary = try? decode([String: Any].self) {
                array.append(nestedDictionary)
            }
            else if let nestedArray = try? decode([Any].self) {
                array.append(nestedArray)
            }
            else {
                print ("WARNING: UnkeyedDecodingContainer.decode: Unsupported JSON type found")
                throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Unsupported JSON type found"))
            }
        }
        
        return array
    }
    
    mutating func decode(_ type: [String: Any].Type) throws -> [String: Any] {
        let nestedContainer = try self.nestedContainer(keyedBy: JSONCodingKeys.self)
        return try nestedContainer.decode(type)
    }
}


// --------------------------------------------------------
//  Encoding
// --------------------------------------------------------

//
// Extend KeyedEncodingContainerProtocol (dictionaries)
//

extension KeyedEncodingContainerProtocol where Key == JSONCodingKeys {
    
    mutating func encode(_ value: [String: Any]) throws {
        try value.forEach({ (key, value) in
            let key = JSONCodingKeys(stringValue: key)

            switch value {
            case let value as any Codable:
                try encode(value, forKey: key)
            case let value as [String: Any]:
                try encode(value, forKey: key)
            case let value as [Any]:
                try encode(value, forKey: key)
            case Optional<Any>.none:
                try encodeNil(forKey: key)
            default:
                throw EncodingError.invalidValue(value,
                    EncodingError.Context(codingPath: codingPath + [key],
                        debugDescription: "Invalid JSON value type \(type(of: value))"))
            }
        })
    }
}

extension KeyedEncodingContainerProtocol {
    
    mutating func encode(_ value: [String: Any]?, forKey key: Key) throws {
        if value != nil {
            var container = self.nestedContainer(keyedBy: JSONCodingKeys.self, forKey: key)
            try container.encode(value!)
        }
    }

    mutating func encode(_ value: [Any]?, forKey key: Key) throws {
        if value != nil {
            var container = self.nestedUnkeyedContainer(forKey: key)
            try container.encode(value!)
        }
    }
}

//
// Extend KeyedEncodingContainerProtocol (arrays)
//

extension UnkeyedEncodingContainer {
    
    mutating func encode(_ value: [Any]) throws {
        try value.enumerated().forEach({ (index, value) in
            switch value {
            case let value as any Codable:
                try encode(value)
            case let value as [String: Any]:
                try encode(value)
            case let value as [Any]:
                try encode(value)
            case Optional<Any>.none:
                try encodeNil()
            default:
                let keys = JSONCodingKeys(intValue: index).map({ [ $0 ] }) ?? []
                throw EncodingError.invalidValue(value,
                    EncodingError.Context(codingPath: codingPath + keys,
                        debugDescription: "Invalid JSON value type \(type(of: value))"))
            }
        })
    }
    
    mutating func encode(_ value: [String: Any]) throws {
        print("encode Dictionary")
        var nestedContainer = self.nestedContainer(keyedBy: JSONCodingKeys.self)
        try nestedContainer.encode(value)
    }
}

