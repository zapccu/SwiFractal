//
//  FractalDocument.swift
//  SwiFractal
//
//  Created by Dirk Braner on 25.02.26.
//

import SwiftUI
import UniformTypeIdentifiers

struct FractalDocument: FileDocument {
    static var readableContentTypes: [UTType] = [.json]
    
    var data: ParameterSet
    
    init(data: ParameterSet) {
        self.data = data
    }
    
    // Initialisator für das Laden bestehender Dateien
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = try JSONDecoder().decode(ParameterSet.self, from: data)
    }

    // Funktion zum Schreiben der Datei
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encodedData = try JSONEncoder().encode(data)
        return FileWrapper(regularFileWithContents: encodedData)
    }
}
