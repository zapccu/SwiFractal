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
    @Binding var info: Info
    
    var body: some View {
        HStack(spacing: 0) {
            Text(info.currentAction)
                .padding([.leading, .trailing], 10)
                .background(Color(red: 0.9, green: 0.9, blue: 0.9))
            Text(info.statusMessage)
                .padding([.leading, .trailing], 10)
                .background(Color(red: 0.9, green: 0.9, blue: 0.9))
            Text(info.mousePosition)
                .padding([.leading, .trailing], 10)
                .background(Color(red: 0.9, green: 0.9, blue: 0.9))
            Spacer()
        }
    }
}
