//
//  DrawingView.swift
//  SwiFractal
//
//  Created by Dirk Braner on 11.02.26.
//

import SwiftUI

//
// Drawing View
//
// Contains the fractal graphic
//
struct DrawingView: View {
    @Binding var redraw: Bool
    @Binding var isDrawing: Bool
    
    var graphics: Graphics
    var fractal: Mandelbrot
    
    var body: some View {
        Canvas { context, size in
            if redraw == redraw {
                print ("drawing cached image")
                graphics.drawImage(context)
            }
        }
        .frame(width: graphics.size.width, height: graphics.size.height, alignment: .topLeading)
        .background(.red)
        // Flip verically: .scaleEffect(CGSize(width: 1, height: -1))
    }

}
