//
//  NamedIntEnum.swift
//  SwiFractal
//
//  Created by Dirk Braner on 21.11.26.
//

import Foundation


///
/// Int-Enum, that appears in JSON as Case-Name (String)
///
protocol NamedIntEnum: RawRepresentable, CaseIterable, Codable, Hashable
    where RawValue == Int {}

extension NamedIntEnum {

    /// Return array with all case names
    static var allNames: [String] { allCases.map(\.name) }

    /// Return array with all allowed Int values
    static var allValues: [Int] { allCases.map(\.rawValue) }

    /// Return true, if rawValue is valid
    static func isValid(_ rawValue: Int) -> Bool { Self(rawValue: rawValue) != nil }

    /// Return name of case
    var name: String { String(describing: self) }

    /// Create case from name
    init?(name: String) {
        guard let match = Self.allCases.first(where: { $0.name == name }) else { return nil }
        self = match
    }

    /// Check if case is in specified list
    func isAny(of list: [Self]) -> Bool { list.contains(self) }
    
    /// Check if case is not in specified list
    func isNone(of list: [Self]) -> Bool { !list.contains(self) }

    // MARK: Codable

    /// Encode case
    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(name)
    }

    /// Decode case
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let string = try? container.decode(String.self) {
            guard let value = Self(name: string) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Invalid case name '\(string)' for \(Self.self), allowed: \(Self.allNames)")
            }
            self = value
        } else {
            // Fallback: support Int values
            let raw = try container.decode(Int.self)
            guard let value = Self(rawValue: raw) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Invalid rawValue \(raw) for \(Self.self), allowed: \(Self.allValues)")
            }
            self = value
        }
    }
    
}
