//
//  ColorConversion.swift
//  SwiFractal
//
//  Created by Dirk Braner on 18.01.25.
//

import Foundation

/// Color type consisting of 3 components
typealias COL3 = SIMD3<Float32>


extension SIMD3<Float32> {
    
    var toFloat: [Float] {
        [Float(x), Float(y), Float(z)]
    }
    
    var tuple3: (Float, Float, Float) {
        (x, y, z)
    }

    init (_ hsb: HSB) {
        self.init(hsb.hue, hsb.saturation, hsb.brightness)
    }
    
    init (_ hsl: HSL) {
        self.init(hsl.hue, hsl.saturation, hsl.lightness)
    }
    
    init (_ lch: LCH) {
        self.init(lch.lightness, lch.chroma, lch.hue)
    }
}

//
// Color model conversion
//

struct ColConv {
    
    //
    // White codes
    //
    enum LabXYZWhite: Int {
        case D65 = 0
        case D50 = 1
        case CIE = 2
    }
    
    
    /// Convert OK/LCH to LAB
    static func oklch2lab(_ oklch: COL3) -> COL3 {
        let (l, c, h) = oklch.tuple3
        let a = c * cos((h * Float.pi) / 180.0)
        let b = c * sin((h * Float.pi) / 180.0)
        return COL3(l, a, b)
    }
    
    /// Convert LAB to XYZ
    static func lab2xyz(_ lab: COL3, white: LabXYZWhite = .D65) -> COL3 {
        let whites: Matrix<Float> = [
            [0.95047,  1.0, 1.08883 ],
            [0.964212, 1.0, 0.825188],
            [0.948110, 1.0, 1.07304 ]
        ]
        
        let (l, a, b) = lab.tuple3
        
        let y = (l + 16.0) / 116.0
        let x = (a / 500.0) + y
        let z = y - (b / 200.0)
        
        var v = [x, y, z]
        for i in 0..<3 {
            v[i] = (v[i] > 0.2068966 ? pow(v[i], 3.0) : (v[i] - 16.0 / 116.0) / 7.78703704) * whites[white.rawValue, i]
        }
        
        return COL3(v)
    }
    
    /// Convert XYZ to RGB
    static func xyz2rgb(_ xyz: COL3) -> COL3 {
        let m: Matrix<Float> = [
            [ 3.24062548, -1.53720797, -0.4986286 ],
            [-0.96893071,  1.87575606,  0.04151752],
            [ 0.05571012, -0.20402105,  1.05699594]
        ]
        
        //let a: [Float] = mulDot(m, xyz.vector3)
        let a: Vector<Float> = m * Vector<Float>(xyz.toFloat)
        let c: [Float] = a.array.map {
            let v0 = max($0, 0.0)
            let v1 = v0 > 0.0031308 ? 1.055 * pow(v0, 1 / 2.4) - 0.055 : 12.92 * v0
            return max(min(v1, 1.0), 0.0)
        }
        
        return COL3(c)
    }
    
    /// Convert HSB to RGB
    static func hsb2rgb(_ hsb: COL3) -> COL3 {
        let (h, s, b) = hsb.tuple3
        
        // Grey
        if s == 0.0 { return COL3(b, b, b) }
        
        var i = Int(h * 6.0)
        let f = (h * 6.0) - Float(i)
        let p = b * (1.0 - s)
        let q = b * (1.0 - s * f)
        let t = b * (1.0 - s * (1.0 - f))
        let v = b
        i = i % 6
        
        switch i {
        case 0: return COL3(v, t, p)
        case 1: return COL3(q, v, p)
        case 2: return COL3(p, v, t)
        case 3: return COL3(p, q, v)
        case 4: return COL3(t, p, v)
        case 5: return COL3(v, p, q)
        default: return COL3(0, 0, 0)
        }
    }
    
    /// Convert HSL to RGB
    static func hsl2rgb(_ hsl: COL3) -> COL3 {
        func hueToRgb(_ p: Float, _ q: Float, _ t: Float) -> Float {
            var x = t
            
            if x < 0 { x += 1 }
            else if x > 1 { x -= 1 }
            
            if x < 1/6 { return p + (q - p) * 6 * x }
            if x < 1/2 { return q }
            if x < 2/3 { return p + (q - p) * (2/3 - x) * 6 }
            
            return p
        }
        
        let (h, s, l) = hsl.tuple3
        
        if s == 0.0 { return COL3(l, l, l) }
        
        let q = l < 0.5 ? l * (1 + s) : l + s - l * s
        let p = 2 * l - q
        
        let r = hueToRgb(p, q, h + 1/3)
        let g = hueToRgb(p, q, h)
        let b = hueToRgb(p, q, h - 1/3)
        
        return COL3(r, g, b)
    }
}
