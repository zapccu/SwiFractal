//
//  FractalDocument.swift
//  SwiFractal
//
//  Created by Dirk Braner on 25.02.26.
//

import SwiftUI
import UniformTypeIdentifiers
import ParSetKit


//
// File document
//
struct FractalJSONDocument: FileDocument {
    
    static var readableContentTypes: [UTType] { [.json] }
    static var writableContentTypes: [UTType] { [.json] }

    var jsonString: String

    init(jsonString: String) {
        self.jsonString = jsonString
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.jsonString = string
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(jsonString.utf8))
    }
    
}

