//
//  DrawMethod.swift
//  SwiFractal
//
//  Created by Dirk Braner on 03.04.26.
//

//
// Draw methods
//
enum DrawMethod : String, CaseIterable, Identifiable {
    case sequential
    case parallel
    case metalcompute
    case metalshader
    
    var id: String { "\(Self.self).\(self.rawValue)" }
}
