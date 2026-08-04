//
//  Presets.swift
//  SwiFractal
//
//  Created by Dirk Braner on 02.04.26.
//

import Foundation


///
/// A fractal parameter preset
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
extension FractalAppData {
    
    /// Array with parameter presets
    @MainActor static let presets: [FractalPreset] = [
        FractalPreset(name: "MandelbrotSet", json: """
        {
            "fractalType": "Mandelbrot",
            "dataType": "MandelbrotParameters<Double>",
            "precision": "double",
            "parameters": {
                "name": "MandelbrotSet",
                "coloring": {
                    "colorizeMode": "iterations",
                    "steps": 0,
                    "stripes": 0,
                    "colorizeInside": "simple",
                    "colorizeOutside": "simple",
                    "ncycle": 1,
                    "stripeSig": 0.9,
                    "paletteMode": "linear",
                    "colorTable": {
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
                    "opacity": 0.75
                },
                "limits": {
                    "bailout": 10000000000,
                    "iterations": 200,
                    "orbitDelta1": 1e-15,
                    "orbitDelta3": 1e-10,
                    "orbitLength": 20,
                    "orbitDelta2": 1e-11,
                    "minIterationCount": 200
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
                "coloring": {
                    "colorizeMode": "stripes",
                    "steps": 0,
                    "stripes": 2,
                    "colorizeInside": "simple",
                    "colorizeOutside": "blinnPhong",
                    "ncycle": 32,
                    "stripeSig": 0.9,
                    "paletteMode": "linear",
                    "colorTable": {
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
                    "cornerX": "-0.5503295086752807",
                    "cornerY": "-0.6259346555912755",
                    "sizeX": "2.0374013587343143e-07",
                    "sizeY": "1.1458947946074716e-07",
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
                    "opacity": 0.75
                },
                "limits": {
                    "bailout": 10000000000,
                    "iterations": 5000,
                    "orbitDelta1": 1e-15,
                    "orbitDelta3": 1e-10,
                    "orbitLength": 20,
                    "orbitDelta2": 1e-11,
                    "minIterationCount": 200
                }
            }
        }
        """),
        FractalPreset(name: "JuliaSet", json: """
        {
             "fractalType": "Julia",
             "dataType": "JuliaParameters<Double>",
             "precision": "double",
             "parameters": {
                 "name": "JuliaSet",
                 "cPointX": 0.0,
                 "cPointY": 0.0,
                 "coloring": {
                     "colorizeMode": "iterations",
                     "steps": 0,
                     "stripes": 0,
                     "colorizeInside": "simple",
                     "colorizeOutside": "simple",
                     "ncycle": 1,
                     "stripeSig": 0.9,
                     "paletteMode": "linear",
                     "colorTable": {
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
                     "opacity": 0.75
                 },
                 "limits": {
                     "bailout": 10000000000,
                     "iterations": 200,
                     "orbitDelta1": 1e-15,
                     "orbitDelta3": 1e-10,
                     "orbitLength": 20,
                     "orbitDelta2": 1e-11,
                     "minIterationCount": 200
                 }
             }
        }
    """)
    ]
    
}
