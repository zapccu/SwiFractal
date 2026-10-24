//
//  based.swift
//  Swift-Toolbox
//
//  Created by Dirk Braner on 07.02.26.
//

import Foundation

///
/// EnumOptions can be used to wrap an Int base enum.
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
///     var options: Options<EnumDrawingAttributes> = Options(.solid)
///
/// With type alias:
///
///         typealias DrawingAttributes = Options<EnumDrawingAttributes>
///
///         var options: DrawingAttributes = Options(.solid)
///
/// *Options* is conform to Codable. An option is converted to a JSON String containing the option name.
///

struct Options<Element>: RawRepresentable, Codable, Equatable
where Element: RawRepresentable, Element: CaseIterable, Element: Equatable, Element.RawValue == Int {

    /// The raw value
	var rawValue: Int
    
    /// Return name of option as String
    var name: String { String(describing: Element(rawValue: rawValue)!) }
    
    /// Return Array with all cases (options) as Strings
    var allNames: [String] = Element.allCases.map { String(describing: $0) }
    
    /// Return rawValue of last option
    var maxValue: Int = Array(Element.allCases).last?.rawValue ?? 0
    
    /// Provide direct access to enum element
    var element: Element {
        get { Element(rawValue: rawValue)! }
        set { if Element.allCases.contains(newValue) { rawValue = newValue.rawValue } }
    }
    
    /// Default initializer
	init() {
		rawValue = 0
	}
    
    /// Init with Int number. If value is > maxValue, initialize with 0
    init (rawValue: Int) {
        self.rawValue = rawValue >= 0 && rawValue <= maxValue ? rawValue : 0
    }
    
    /// Init from String
    init(value: String) {
        if let v = allNames.firstIndex(of: value) {
            self.rawValue = v
        }
        else {
            self.rawValue = 0
        }
    }

    /// Initialize Options with option
    /// Example: options = Options(.opt1)
    /// This function is also called for decoding keyed JSON strings like "{ \"key\":  \"opt11\”  }"
    ///
    init(_ element: Element) {
        self.rawValue = element.rawValue
    }
    
    /// Update option
    /// - Parameter element: New option / element
    mutating func callAsFunction(_ element: Element) {
        self.rawValue = element.rawValue
    }
    
    /// Return current option / element
    func callAsFunction() -> Element {
        Element(rawValue: rawValue)!
    }
    
    /// Returns name of option *Element* as String
    func optName(_ option: Element) -> String {
        return String(describing: option)
    }
    
    /// Return true if option is in list *Element*
    func isAny(of: [Element]) -> Bool {
        return of.contains(where: { self.rawValue == $0.rawValue })
    }
    
    /// Compare options
    static func == (lhs: Options<Element>, rhs: Options<Element>) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
    
    /// Compare options
    static func != (lhs: Options<Element>, rhs: Options<Element>) -> Bool {
        return lhs.rawValue != rhs.rawValue
    }
    
    static func == (lhs: Options<Element>, rhs: Element) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
    
    static func != (lhs: Options<Element>, rhs: Element) -> Bool {
        return lhs.rawValue != rhs.rawValue
    }
    
    /// Put option name as String into JSON instead of rawValue
    /// - Parameter encoder: Encoder
    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(name)
    }
    
    /// Decode from JSON string
    /// This function is called for keyless JSON strings like " \"case1\" "
    /// - Parameter decoder: Decoder
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.rawValue = 0
        let strValue = try container.decode(String.self)
        if let optIndex = allNames.firstIndex(of: strValue) {
            rawValue = Element.allCases[optIndex as! Element.AllCases.Index].rawValue
        }
    }
    
    /// Convert JSON string to Option
    /// - Parameter jsonString: JSON string
    /// - Returns: true on success, false on error
    mutating func fromJSON(_ jsonString: String) -> Bool {
        guard let data = jsonString.data(using: .utf8) else { return false }
        do {
            let newOptions = try JSONDecoder().decode(Options.self, from: data)
            self.rawValue = newOptions.rawValue
            return true
        }
        catch {
            return false
        }
    }
    
    /// Convert Option to (optionally) formatted JSON string
    /// Returns JSON string or empty string on error
    /// - Parameter prettyPrinted: If true JSON string is formatted
    /// - Returns: JSON string or empty string on error
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
}

/*
struct OptionRule<Element1, Element2>
where Element1: OptionElement, Element2: OptionElement, Element1.RawValue == Int, Element2.RawValue == Int {
    let when: Options<Element1>
    let then: Options<Element2>
}

struct OptionMapper<Element1, Element2>
where Element1: OptionElement, Element2: OptionElement, Element1.RawValue == Int, Element2.RawValue == Int {
    let rules: [OptionRule<Element1, Element2>]
    
    func map(_ element1: Element1) -> Options<Element2>? {
        rules.first(where: { $0.when == element1 })?.then
    }
}
*/
