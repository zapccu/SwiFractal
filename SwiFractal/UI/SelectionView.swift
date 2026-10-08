//
//  SelectionView.swift
//  SwiFractal
//
//  Created by Dirk Braner on 11.02.26.
//

import SwiftUI


///
/// Selection View
///
/// Placed on top of the drawing view for interactively selecting a view area
///
struct SelectionView: View {
    
    var controller: FractalController

    var body: some View {
        Canvas { context, size in
            let graphics = CanvasGraphics(context: context, size: size)
            controller.selection.draw(graphics)
        }
        .gesture(controller.handleSelection())
    }
    
}
