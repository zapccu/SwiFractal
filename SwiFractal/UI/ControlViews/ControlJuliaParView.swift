//
//  ControlJuliaParamtersView.swift
//  SwiFractal
//
//  Created by Dirk Braner on 04.08.26.
//

import SwiftUI


//
// Julia set specific parameters
//
struct JuliaParView<RT: PreciseFloatingPoint>: View {
    
    var fractal: Julia<RT>
        
    var body: some View {
        //
        // Julia point
        //
        GroupBox(label: Text("Juliaset point").foregroundStyle(.blue).font(.headline)) {
            VStack(alignment: .leading) {
                LabeledInputField("Real", Bindable(fractal).FP.strCPointX, width: 170)
                LabeledInputField("Imag", Bindable(fractal).FP.strCPointY, width: 170)
            }
        }.padding([.top], 10)
    }
    
}

