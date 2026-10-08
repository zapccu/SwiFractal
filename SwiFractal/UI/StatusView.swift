//
//  StatusView.swift
//  SwiFractal
//
//  Created by Dirk Braner on 11.02.26.
//

import SwiftUI

///
/// Status view
///
/// Used for showing status information on bottom of window
///
struct StatusView: View {
    var controller: FractalController
    
    var body: some View {
        HStack(spacing: 0) {
            Text(controller.info.currentAction)
                .padding([.leading, .trailing], 10)
            Divider()
            Text(controller.info.statusMessage)
                .padding([.leading, .trailing], 10)

            if controller.selection.state == .selecting || controller.selection.areaSelected {
                Divider()
                Text(controller.selection.areaString)
                    .padding([.leading, .trailing], 10)
            }
            else if !controller.info.mousePosition.isEmpty {
                Divider()
                Text(controller.info.mousePosition)
                    .padding([.leading, .trailing], 10)
            }
            Spacer()
        }.background(Color.yellow.opacity(0.5))
    }
}
