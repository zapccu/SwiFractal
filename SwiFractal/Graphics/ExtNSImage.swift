//
//  NSImageExt.swift
//  SwiFractal
//
//  Created by Dirk Braner on 30.04.26.
//

import SwiftUI

extension NSImage {
    
    // Save NSImage to file
    func saveToFile(path: String) -> Bool {
        let imageRep = NSBitmapImageRep(data: self.tiffRepresentation!)
        let pngData = imageRep?.representation(using: NSBitmapImageRep.FileType.png, properties: [:])
        do {
            try pngData!.write(to: URL(filePath: path))
        } catch {
            return false
        }
        
        return true
    }
}
