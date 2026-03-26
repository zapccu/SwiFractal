//
//  FractalDocument.swift
//  SwiFractal
//
//  Created by Dirk Braner on 25.02.26.
//

import SwiftUI
import UniformTypeIdentifiers
import ParSetKit


struct FractalDocument<T: FractalData>: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    
    var data: ParSet<T>
    
    init(data: ParSet<T>) {
        self.data = data
    }
    
    // Initialization from existing file
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = try JSONDecoder().decode(ParSet<T>.self, from: data)
    }

    // Funktion zum Schreiben der Datei
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encodedData = try JSONEncoder().encode(data)
        return FileWrapper(regularFileWithContents: encodedData)
    }
}
