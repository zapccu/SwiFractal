//
//  Presets.swift
//  SwiFractal
//
//  Created by Dirk Braner on 02.04.26.
//

import Foundation


///
/// Fractal parameter preset
///
struct FractalPreset {
    let name: String    // Name of preset
    let json: String    // Export-Envelope-JSON (compatible to exportJSONString())
    
    /// Decode JSON data and return fractal export header
    var header: FractalExportHeader? {
        do {
            let header = try JSONDecoder().decode(FractalExportHeader.self, from: Data(json.utf8))
            return header
        }
        catch {
            print("Error decoding header for preset \(name): \(error)")
            return nil
        }
    }
}

//
// Parameter presets
//
extension FractalController {
    
    /// Apply new preset by importing JSON definition
    /// - Parameters:
    ///   - preset: Fractal parameter preset
    ///   - fit: Aspect ratio mode. Default = .ignoreAspectRatio
    func applyPreset(preset: FractalPreset, fit: AspectRatioMode = .ignoreAspectRatio) {
        do {
            let kind = try FractalRegistry.importJSON(fromString: preset.json)
            setFractal(kind: kind, fit: fit)
        }
        catch {
            debugPrint("Error applying preset \(preset.name): \(error)")
        }
    }
    
    /// Apply preset specified by name by importing JSON definition
    /// - Parameters:
    ///   - preset: Name of fractal parameter preset
    ///   - fit: Aspect ratio mode. Default = .ignoreAspectRatio
    func applyPreset(name: String, fit: AspectRatioMode = .ignoreAspectRatio) {
        debugPrint("Applying preset: \(name)")
        guard let preset = Self.presets.first(where: { $0.name == name }) else {
            debugPrint("Preset \(name) not found")
            return
        }
        applyPreset(preset: preset, fit: fit)
    }
    
    /// Array with parameter presets
    static let presets: [FractalPreset] = [
        FractalPreset(name: "MandelbrotSet", json: """
        {
            "fractalType": "Mandelbrot",
            "dataType": "MandelbrotParameters<Double>",
            "precision": "double",
            "parameters": {
                "name": "MandelbrotSet",
                "colorParameters": {
                    "colorizeMode": "iterations",
                    "colorizeInside": "simple",
                    "colorizeOutside": "simple",
                    "paletteMode": "linear",
                    "steps": 0,
                    "stripes": 0,
                    "stripeSig": 0.9,
                    "ncycle": 1,
                    "scale": 1,
                    "offset": 0,
                    "compression": 1,
                    "coloringName": "Grey-1024",
                    "coloring": {
                        "smooth": {
                            "smoothColorTable": {
                                "name": "Grey-1024",
                                "count": 1024,
                                "defColor": {
                                    "alpha": 1,
                                    "blue": 0,
                                    "red": 0,
                                    "green": 0
                                },
                                "fixedSize": false,
                                "colorPoints": [
                                    {
                                        "alpha": 1,
                                        "blue": 0.3137255,
                                        "red": 0.3137255,
                                        "green": 0.3137255
                                    },
                                    {
                                        "alpha": 1,
                                        "blue": 1,
                                        "red": 1,
                                        "green": 1
                                    }
                                ]
                            }
                        }
                    }
                },
                "dimensions": {
                    "cornerX": -2.25,
                    "cornerY": -1.5,
                    "sizeY": 3,
                    "sizeX": 3,
                    "oversampling": 1,
                    "renderPrecision": "double",
                    "precision": {
                        "isDbl": true,
                        "bits": 53
                    }
                },
                "lightParameters": {
                    "shininess": 20,
                    "ambient": 0.2,
                    "angle": 45,
                    "gamma": 1,
                    "diffuse": 0.5,
                    "elevation": 45,
                    "specular": 0.5,
                    "opacity": 0.75,
                    "ev": 0,
                    "blendingMode": "none"
                },
                "limits": {
                    "bailout": 10000000000,
                    "iterations": 200,
                    "orbitDelta1": 1e-15,
                    "orbitDelta3": 1e-10,
                    "orbitLength": 20,
                    "orbitDeltaF": 1e4,
                    "interiorTolerance": 1e-13,
                    "minIterationCount": 200
                }
            }
        }
        """),
        FractalPreset(name: "Crown", json: """
        {
            "fractalType": "Mandelbrot",
            "dataType": "MandelbrotParameters<Double>",
            "precision": "double",
            "parameters": {
                "name": "Crown",
                "colorParameters": {
                    "colorizeMode": "stripes",
                    "steps": 0,
                    "stripes": 2,
                    "colorizeInside": "simple",
                    "colorizeOutside": "blinnPhong",
                    "ncycle": 32,
                    "stripeSig": 0.9,
                    "paletteMode": "linear",
                    "scale": 1,
                    "offset": 0,
                    "compression": 2,
                    "coloringName": "Crown-11_02_92-4096",
                    "coloring": {
                        "sine": {
                            "sineColorTable": {
                                "name": "Crown-11_02_92-4096",
                                "count": 4096,
                                "defColor": {
                                    "red": 0,
                                    "green": 0,
                                    "blue": 0,
                                    "alpha": 1
                                },
                                "fixedSize": false,
                                "thetas": [
                                    0.11,
                                    0.02,
                                    0.92
                                ]
                            }
                        }
                    }
                },
                "dimensions": {
                    "cornerX": -0.5503295086752807,
                    "cornerY": -0.6259346555912755,
                    "sizeX": 2.0374013587343143e-07,
                    "sizeY": 1.1458947946074716e-07,
                    "oversampling": 1,
                    "renderPrecision": "double",
                    "precision": {
                        "isDbl": true,
                        "bits": 53
                    }
                },
                "lightParameters": {
                    "shininess": 20,
                    "ambient": 0.2,
                    "angle": 45,
                    "gamma": 1,
                    "diffuse": 0.5,
                    "elevation": 45,
                    "specular": 0.5,
                    "opacity": 0.75,
                    "ev": 0,
                    "blendingMode": "overlay"
                },
                "limits": {
                    "bailout": 10000000000,
                    "iterations": 5000,
                    "orbitDelta1": 1e-15,
                    "orbitDelta3": 1e-10,
                    "orbitLength": 20,
                    "orbitDeltaF": 1e4,
                    "interiorTolerance": 1e-13,
                    "minIterationCount": 200
                }
            }
        }
        """),
        FractalPreset(name: "Pow", json: """
        {
            "fractalType": "Mandelbrot",
            "dataType": "MandelbrotParameters<Double>",
            "precision": "double",
            "parameters": {
                "name": "Pow",
                "colorParameters": {
                    "colorizeMode": "stripes",
                    "steps": 10,
                    "stripes": 0,
                    "colorizeInside": "simple",
                    "colorizeOutside": "blinnPhong",
                    "ncycle": 8,
                    "stripeSig": 0.9,
                    "paletteMode": "linear",
                    "scale": 1,
                    "offset": 0,
                    "compression": 1,
                    "coloringName": "Pow-29_02_9-4096",
                    "coloring": {
                        "sine": {
                            "sineColorTable": {
                                "name": "Pow-29_02_9-4096",
                                "count": 4096,
                                "defColor": {
                                    "red": 0,
                                    "green": 0,
                                    "blue": 0,
                                    "alpha": 1
                                },
                                "fixedSize": false,
                                "thetas": [
                                    0.29,
                                    0.02,
                                    0.9
                                ]
                            }
                        }
                    }
                },
                "dimensions": {
                    "cornerX": -1.9854527029227764,
                    "cornerY": 0.00019009159314173224,
                    "sizeX": 1.6118262280429008e-10,
                    "sizeY": 9.065738833463968e-11,
                    "oversampling": 1,
                    "renderPrecision": "double",
                    "precision": {
                        "isDbl": true,
                        "bits": 53
                    }
                },
                "lightParameters": {
                    "shininess": 20,
                    "ambient": 0.2,
                    "angle": 45,
                    "gamma": 1,
                    "diffuse": 0.5,
                    "elevation": 45,
                    "specular": 0.5,
                    "opacity": 0.75,
                    "ev": 0,
                    "blendingMode": "overlay"
                },
                "limits": {
                    "bailout": 10000000000,
                    "iterations": 5000,
                    "orbitDelta1": 1e-15,
                    "orbitDelta3": 1e-10,
                    "orbitLength": 20,
                    "orbitDeltaF": 1e4,
                    "interiorTolerance": 1e-13,
                    "minIterationCount": 200
                }
            }
        }
        """),
        FractalPreset(name: "San Marco", json: """
        {
            "fractalType": "Julia",
            "dataType": "JuliaParameters<Double>",
            "precision": "double",
            "parameters": {
                "name": "San Marco",
                "cPointX": -0.75,
                "cPointY": 0.0,
                "colorParameters": {
                    "colorizeMode": "iterations",
                    "steps": 0,
                    "stripes": 0,
                    "colorizeInside": "simple",
                    "colorizeOutside": "simple",
                    "ncycle": 1,
                    "stripeSig": 0.9,
                    "paletteMode": "linear",
                    "scale": 1,
                    "offset": 0,
                    "compression": 1,
                    "coloringName": "Grey-1024",
                    "coloring": {
                        "smooth": {
                            "smoothColorTable": {
                                "name": "Grey-1024",
                                "count": 1024,
                                "defColor": {
                                    "alpha": 1,
                                    "blue": 0,
                                    "red": 0,
                                    "green": 0
                                },
                                "fixedSize": false,
                                "colorPoints": [
                                    {
                                        "alpha": 1,
                                        "blue": 0.3137255,
                                        "red": 0.3137255,
                                        "green": 0.3137255
                                    },
                                    {
                                        "alpha": 1,
                                        "blue": 1,
                                        "red": 1,
                                        "green": 1
                                    }
                                ]
                            }
                        }
                    }
                },
                "dimensions": {
                    "cornerX": -1.5,
                    "cornerY": -1.5,
                    "sizeY": 3,
                    "sizeX": 3,
                    "oversampling": 1,
                    "renderPrecision": "double",
                    "precision": {
                        "isDbl": true,
                        "bits": 53
                    }
                },
                "lightParameters": {
                    "shininess": 20,
                    "ambient": 0.2,
                    "angle": 45,
                    "gamma": 1,
                    "diffuse": 0.5,
                    "elevation": 45,
                    "specular": 0.5,
                    "opacity": 0.75,
                    "ev": 0,
                    "blendingMode": "none"
                },
                "limits": {
                    "bailout": 10000000000,
                    "iterations": 200,
                    "orbitDelta1": 1e-15,
                    "orbitDelta3": 1e-10,
                    "orbitLength": 20,
                    "orbitDeltaF": 1e4,
                    "interiorTolerance": 1e-13,
                    "minIterationCount": 200
                }
            }
        }
        """),
        FractalPreset(name: "Blue Julia", json: """
        {
            "fractalType": "Julia",
            "dataType": "JuliaParameters<Double>",
            "precision": "double",
            "parameters": {
                "name": "Blue Julia",
                "cPointX": -0.7269,
                "cPointY": 0.1889,
                "colorParameters": {
                    "colorizeMode": "iterations",
                    "steps": 0,
                    "stripes": 0,
                    "colorizeInside": "simple",
                    "colorizeOutside": "blinnPhong",
                    "ncycle": 1,
                    "stripeSig": 0,
                    "paletteMode": "linear",
                    "scale": 1,
                    "offset": 0,
                    "compression": 1,
                    "coloringName": "BlueJulia-85_0_15-4096",
                    "coloring": {
                        "sine": {
                            "sineColorTable": {
                                "name": "BlueJulia-85_0_15-4096",
                                "count": 4096,
                                "defColor": {
                                    "red": 0,
                                    "green": 0,
                                    "blue": 0,
                                    "alpha": 1
                                },
                                "fixedSize": false,
                                "thetas": [
                                    0.85,
                                    0.0,
                                    0.15
                                ]
                            }
                        }
                    }
                },
                "dimensions": {
                    "cornerX": -1.5,
                    "cornerY": -1.5,
                    "sizeY": 3,
                    "sizeX": 3,
                    "oversampling": 1,
                    "renderPrecision": "double",
                    "precision": {
                        "isDbl": true,
                        "bits": 53
                    }
                },
                "lightParameters": {
                    "shininess": 20,
                    "ambient": 0.2,
                    "angle": 45,
                    "gamma": 1,
                    "diffuse": 0.5,
                    "elevation": 45,
                    "specular": 0.5,
                    "opacity": 0.75,
                    "ev": 0,
                    "blendingMode": "none"
                },
                "limits": {
                    "bailout": 10000000000,
                    "iterations": 2000,
                    "orbitDelta1": 1e-15,
                    "orbitDelta3": 1e-10,
                    "orbitLength": 20,
                    "orbitDeltaF": 1e4,
                    "interiorTolerance": 1e-13,
                    "minIterationCount": 200
                }
            }
        }
        """)
    ]
    
}
