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
    //var fractal: Fractal
    
    var body: some View {
        Canvas { context, size in
            if redraw == redraw {
                print ("drawing cached image")
                graphics.drawImage(context)
            }
        }
        .frame(width: graphics.frameSize.width, height: graphics.frameSize.height, alignment: .topLeading)
        .background(Color(CGColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)))
        // Flip verically: .scaleEffect(CGSize(width: 1, height: -1))
    }

}
