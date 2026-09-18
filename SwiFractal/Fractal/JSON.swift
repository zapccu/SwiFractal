//
//  JSON.swift
//  SwiFractal
//
//  Created by Dirk Braner on 21.07.26.
//

import Foundation
import SwiftMPx


///
/// Export header and data
///
struct FractalExportData<DataType: FractalData>: Codable {
    let fractalType: String
    let dataType: String
    let precision: PrecisionTag
    let parameters: DataType
}

///
/// Import header before exact data type is known.
/// JSONDecoder ignores unknown keys ("parameters")
///
struct FractalExportHeader: Decodable {
    let fractalType: String
    let dataType: String
    let precision: PrecisionTag
}

///
/// I/O error handling
///
enum FractalIOError: LocalizedError {
    case encodingFailed
    case decodingFailed
    case unknownType(String)
    case underlying(Error)

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Das Fraktal konnte nicht als JSON kodiert werden."
        case .decodingFailed:
            return "Die JSON-Daten konnten nicht gelesen werden."
        case .unknownType(let key):
            return "Unbekannter Fraktaltyp „\(key)“ in der JSON-Datei."
        case .underlying(let error):
            return error.localizedDescription
        }
    }

    var failureReason: String? {
        switch self {
        case .unknownType:
            return "Der Typ ist in der aktuellen Version von SwiFractal nicht registriert."
        case .underlying(let error):
            return (error as? LocalizedError)?.failureReason
        default:
            return nil
        }
    }
}


//
// Enhance FractalProtcol to support export to JSON
//
extension FractalProtocol {
    
    func exportJSONString() throws -> String {
        let envelope = FractalExportData(
            fractalType: fractalType,
            dataType: DataType.dataType,
            precision: RT.precisionTag,
            parameters: FP.current
        )
        let data = try JSONEncoder().encode(envelope)
        guard let string = String(data: data, encoding: .utf8) else {
            throw FractalIOError.encodingFailed
        }
        return string
    }

    func exportJSON(to url: URL) throws {
        try exportJSONString().write(to: url, atomically: true, encoding: .utf8)
    }
    
}

typealias FractalFactory = (Data) throws -> FractalKind

///
/// Fractal registry. Import fractal from JSON data
///
@MainActor
enum FractalRegistry {

    static let factories: [String: FractalFactory] = [
        "Mandelbrot.double": { data in
            let envelope = try JSONDecoder()
                .decode(FractalExportData<MandelbrotParameters<Double>>.self, from: data)
            return .mandelbrotDP(Mandelbrot(mandelbrotParameters: envelope.parameters))
        },
        "Mandelbrot.arbitrary": { data in
            let envelope = try JSONDecoder()
                .decode(FractalExportData<MandelbrotParameters<MPFloat>>.self, from: data)
            return .mandelbrotAP(Mandelbrot(mandelbrotParameters: envelope.parameters))
        },
        "Julia.double": { data in
            let envelope = try JSONDecoder()
                .decode(FractalExportData<JuliaParameters<Double>>.self, from: data)
            return .juliaDP(Julia(juliaParameters: envelope.parameters))
        },
        "Julia.arbitrary": { data in
            let envelope = try JSONDecoder()
                .decode(FractalExportData<JuliaParameters<MPFloat>>.self, from: data)
            return .juliaAP(Julia(juliaParameters: envelope.parameters))
        }
    ]
    
    /// Import fractal from JSON data
    /// - Parameter data: JSON data
    /// - Returns: Fractal kind
    static func importJSON(from data: Data) throws -> FractalKind {
        let header: FractalExportHeader
        do {
            header = try JSONDecoder().decode(FractalExportHeader.self, from: data)
        } catch {
            throw FractalIOError.underlying(error)
        }

        let key = "\(header.fractalType).\(header.precision.rawValue)"
        guard let factory = factories[key] else {
            throw FractalIOError.unknownType(key)
        }

        do {
            return try factory(data)
        } catch {
            throw FractalIOError.underlying(error)
        }
    }
    
    /// Import fractal from JSON string
    /// - Parameter string: JSON string
    /// - Returns: Fractal kind
    static func importJSON(fromString string: String) throws -> FractalKind {
        guard let data = string.data(using: .utf8) else {
            throw FractalIOError.decodingFailed
        }
        return try importJSON(from: data)
    }
    
    /// Import fractal from URL
    /// - Parameter url: URL
    /// - Returns: Fractal kind
    static func importJSON(from url: URL) throws -> FractalKind {
        try importJSON(from: try Data(contentsOf: url))
    }
}

extension FractalKind {
    
    /// Export current fractal parameters to JSON string
    /// - Returns: JSON String
    func exportJSONString() throws -> String {
        switch self {
        case .mandelbrotDP(let f): return try f.exportJSONString()
        case .mandelbrotAP(let f): return try f.exportJSONString()
        case .juliaDP(let f):      return try f.exportJSONString()
        case .juliaAP(let f):      return try f.exportJSONString()
        }
    }
    
}
