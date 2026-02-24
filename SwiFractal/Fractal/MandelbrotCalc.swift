//
//  MandelbrotCalc.swift
//  SwiFractal
//
//  Created by Dirk Braner on 23.02.26.
//

import SwiftUI

extension Mandelbrot {
    
    /// Calculate a line without modifying graphics color and drawing position
    func calculateLine(_ graphics: Graphics, _ y: Int) {
        var color = calculatePointZ2(0, y)
        var pt = CGPoint(x: 0, y: y)
        
        for x in 1..<graphics.width {
            let newColor = calculatePointZ2(x, y)
            if newColor != color {
                pt = graphics.drawHLine(pt, x, color: color)
                color = newColor
            }
        }
        
        _ = graphics.drawHLine(pt, graphics.width, color: color)
    }
    
    /// Parallel calculation of Mandelbrot set
    func calculateParallel(_ graphics: Graphics) {
        // Calculate cpuCount lines in parallel
        DispatchQueue.concurrentPerform(iterations: cpuCount) { i in
            for y in stride(from: i, to: graphics.height, by: cpuCount) {
                calculateLine(graphics, y)
            }
        }
    }
    
    /// Metal / GPU calculation of Mandelbrot set
    func calculateMetal(_ graphics: Graphics) {
        // Convert complex grid to 1 dimensional array
        let C = cplxGrid.joined().map { Complex2($0) }
        
        do {
            let metalCompute = try MetalCompute("mandelbrot")
            
            try metalCompute.addBuffer(C, .computeInputBuffer)
            try metalCompute.addBuffer(MP.colorMapping.palette.rgbaColors, .inputBuffer)
            metalCompute.addObject(MP.computeParameters)
            
            // Compute Mandelbrot set
            let result = try metalCompute.compute(RGBAColor.black.rgba)
            graphics.initFromColorArray(result)
        }
        catch {
            print(error)
        }
    }
    
    
    /// Sequential calculation of Mandelbrot set line by line
    func calculateLineByLine(_ graphics: Graphics) {
        for y in 0..<graphics.height {
            calculateLine(graphics, y)
        }
        
        if MP.bHist {
            let total = Double(pixelCountPerIteration.reduce(0, +))
            for y in 0..<graphics.height {
                for x in 0..<graphics.width {
                    let iter = iterationCountPerPixel[y][x]
                    if iter == MP.iterations { continue }
                    var hue = 0.0
                    for i in 0...iter {
                        hue += Double(pixelCountPerIteration[i]) / total
                        let ci = Int(Double(MP.colorMapping.colorCount) * hue)
                        graphics.setPixel(x, y, color: MP.colorMapping[ci])
                    }
                }
            }
        }
    }
}
