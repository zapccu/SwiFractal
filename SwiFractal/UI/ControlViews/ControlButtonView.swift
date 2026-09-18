//
//  ButtonView.swift
//  SwiFractal
//
//  Created by Dirk Braner on 23.03.26.
//

import SwiftUI
import SwiftMPx


//
// View containing the control buttons
//
struct ControlButtonView: View {
    @Environment(AppSettings.self) private var settings

    let controller: FractalController   // Fractal controller
    let method: CalculationMethod       // Calculation method
    
    @Binding var info: Info
    
    @State private var calculationTask: Task<Void, Never>? = nil
    
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var exportDocument = FractalJSONDocument(jsonString: "")
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        GroupBox(label: Text("Actions").foregroundStyle(.blue).font(.headline))  {
            VStack(alignment: .leading) {
                HStack(spacing: 5) {
                    // Button "Apply"
                    Button(action: {
                        controller.applyNewParameters()
                    }) {
                        Image(systemName: "app.badge.checkmark").font(.title)
                    }
                    .disabled(!controller.parametersChanged)
                    .help("Apply current dimensions")
                    
                    // Button "Undo"
                    Button(action: {
                        controller.undo()
                    }) {
                        Image(systemName: "arrow.uturn.backward").font(.title)
                    }
                    .disabled(!controller.parametersChanged)
                    .help("Undo last change")
                    
                    // Reset
                    Button(action: {
                        controller.fractal.reset()
                    }) {
                        Image(systemName: "delete.left").font(.title)
                    }
                    .disabled(controller.fractal.versionsCount < 2)
                    .help("Reset to default parameters")
                    
                    // Draw
                    Button(action: {
                        info.setState(currentAction: "Drawing ...")

                        calculationTask = Task {
                            // Render fractal
                            controller.beginCalculation()
                            let st = await controller.calculate(method: method)
                            guard !Task.isCancelled else {
                                controller.endCalculation(.cancelled("Cancelled."))
                                info.setState(currentAction: "Cancelled.")
                                return
                            }
                            controller.endCalculation(st)
                            if settings.drawParallel {
                                debugPrint("Drawing parallel")
                                await controller.drawResultSetParallel()
                            }
                            else {
                                debugPrint("Drawing sequential")
                                await controller.drawResultSet()
                            }
/*
                            let (st, image) = await controller.fractal.render(method: method, resolution: controller.resolution)
                            guard !Task.isCancelled else {
                                controller.endCalculation(.cancelled("Cancelled."))
                                info.setState(currentAction: "Cancelled.")
                                return
                            }
                            
                            controller.image = image
                            controller.endCalculation(st)
 */
                            info.setState(currentAction: st.message, statusMessage: "Calculation time: \(controller.formattedCalculationTime)")
                        }

                        controller.selection.reset()
                    }) {
                        Image(systemName: "scribble").font(.title)
                    }
                    .disabled(controller.isCalculating)
                    .help("Draw fractal")
                    
                    // Stop calculation
                    Button(action: {
                        calculationTask?.cancel()
                        calculationTask = nil
                    }) {
                        Image(systemName: "stop.fill").font(.title)
                    }
                    .disabled(!controller.isCalculating)
                    .help("Stop drawing")
                }

                //
                // File export/import
                //
                HStack(spacing: 5) {
                    Button(action: {
                        do {
                            exportDocument = FractalJSONDocument(jsonString: try controller.kind.exportJSONString())
                            isExporting = true
                        } catch {
                            present(error)
                        }
                    }) {
                        Image(systemName: "arrow.down.square").font(.title)
                    }

                    Button(action: {
                        isImporting = true
                    }) {
                        Image(systemName: "arrow.up.right.square").font(.title)
                    }
                }
                .fileExporter(
                    isPresented: $isExporting,
                    document: exportDocument,
                    contentType: .json,
                    defaultFilename: "fractal"
                ) { result in
                    if case .failure(let error) = result { present(error) }
                }
                .fileImporter(
                    isPresented: $isImporting,
                    allowedContentTypes: [.json]
                ) { result in
                    switch result {
                    case .success(let url):
                        importFractal(from: url)
                    case .failure(let error):
                        present(error)
                    }
                }
                .alert("Error", isPresented: $showError) {
                    Button("OK") { }
                } message: {
                    Text(errorMessage)
                }
            }
        }.padding([.top], 10)
    }
    
    private func importFractal(from url: URL) {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer { if didAccess { url.stopAccessingSecurityScopedResource() } }

        do {
            let kind = try FractalRegistry.importJSON(from: url)
            controller.setFractal(kind: kind)
        } catch {
            present(error)
        }
    }

    private func present(_ error: Error) {
        errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        showError = true
    }
}
