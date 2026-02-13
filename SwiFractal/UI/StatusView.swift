//
//  StatusView.swift
//  SwiFractal
//
//  Created by Dirk Braner on 11.02.26.
//

import SwiftUI

//
// Status view
//
// Used for showing status information on bottom of window
//
struct StatusView: View {
    @Binding var currentAction: String
    
    var body: some View {
        HStack(spacing: 0) {
            Text(currentAction)
            Spacer()
        }
    }
}
