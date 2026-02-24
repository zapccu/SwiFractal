//
//  SelectionView.swift
//  SwiFractal
//
//  Created by Dirk Braner on 11.02.26.
//

import SwiftUI

//
// Selection View
//
// Placed on top of the drawing view for interactively selecting a view area
//
struct SelectionView: View {
    @Binding var selection: Selection
    var size: CGSize

    private func handleSelection() -> some Gesture {
        return DragGesture(minimumDistance: 0)
            .onChanged { event in
                selection.onChanged(event, CGRect(origin: .zero, size: size))
            }
            .onEnded{ event in
                selection.onEnded(event, CGRect(origin: .zero, size: size))
            }
    }

    var body: some View {
        Canvas { context, size in
            let graphics = CanvasGraphics(context, size)
            selection.draw(graphics)
        }
        .gesture(handleSelection())
    }
}
