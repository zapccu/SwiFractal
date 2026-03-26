//
//  ButtonView.swift
//  SwiFractal
//
//  Created by Dirk Braner on 23.03.26.
//

import SwiftUI

struct ControlButtonView<T: FractalData>: View {
    var fractal: Fractal<T>
    var graphics: Graphics
    var selection: Selection
    
    @Binding var currentAction: String
    @Binding var message: String
    @Binding var isDrawing: Bool
    @Binding var redraw: Bool
    
    @State var drawMethod: DrawMethod = .sequential

    var body: some View {
        GroupBox(label: Text("Actions").foregroundStyle(.blue).font(.headline))  {
            VStack(alignment: .leading) {
                HStack(spacing: 5) {
                    Button("Apply") {
                        if selection.state == .areaSelected {
                            let area = selection.getArea(flipped: true, height: graphics.height)
                            let (newCorner, newSize) = fractal.zoomArea(area, graphics.width, graphics.height)
                            fractal.FP.newVersion()
                            fractal.FP.common.cornerX = String(newCorner.real)
                            fractal.FP.common.cornerY = String(newCorner.imaginary)
                            fractal.FP.common.sizeX   = String(newSize.real)
                            fractal.FP.common.sizeY   = String(newSize.imaginary)
                        }
                    }
                    Button("Draw") {
                        Task(priority: .userInitiated) {
                            if graphics.beginDraw() {
                                currentAction = "Drawing ..."
                                message = ""
                                isDrawing = true
                                _ = await Task.detached(priority: .userInitiated) {
                                    return await fractal.draw(graphics, drawMethod)
                                }.value
                                isDrawing = false
                                graphics.endDraw()
                                currentAction = "Done."
                                message = "Calculation time: \(fractal.formattedCalculationTime)"
                                selection.reset()
                                redraw.toggle()
                            }
                        }
                    }.disabled(isDrawing)
                    Button("Reset") {
                        fractal.resetSettings()
                    }
                }

                if let mandelbrot = fractal as? Mandelbrot {
                    HStack(spacing: 5) {
                        ExportButton(document: FractalDocument(data: mandelbrot.FP))
                    
                        ImportButton<MandelbrotParameters> { decodedData in
                            mandelbrot.FP = decodedData
                        }
                    }
                }
            }
        }.padding([.top], 10)
    }
}
