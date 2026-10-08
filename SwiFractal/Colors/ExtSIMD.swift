//
//  ExtSIMD.swift
//  SwiFractal
//
//  Created by Dirk Braner on 03.10.26.
//

import Foundation
import SwiftUI
import simd


extension SIMD3: @retroactive ExpressibleByFloatLiteral where Scalar: ExpressibleByFloatLiteral {
    
    public init(floatLiteral value: Scalar.FloatLiteralType) {
        self.init(repeating: Scalar(floatLiteral: value))
    }
    
}

extension SIMD3 where Scalar == Float {
    
    static func *= (_ value: inout Self, _ scalar: Scalar) {
        value.x *= scalar
        value.y *= scalar
        value.z *= scalar
    }
    
    var asRGBA: SIMD4<Scalar> {
        return SIMD4<Scalar>(
            x: RGBAColor.linearToRGB(x),
            y: RGBAColor.linearToRGB(y),
            z: RGBAColor.linearToRGB(z),
            w: 1.0
        )
    }
    
}

extension SIMD4 {
    
    /// Access elements x,y,z as SIMD3
    var xyz: SIMD3<Scalar> {
        get { SIMD3(x, y, z) }
        set {
            self.x = newValue.x
            self.y = newValue.y
            self.z = newValue.z
        }
    }
    
    /// Initialize SIMD4 value with SIMD3 and scalar value
    init(xyz: SIMD3<Scalar>, w: Scalar) {
        self.init(xyz.x, xyz.y, xyz.z, w)
    }
    
}

// Extension for RGBA type
extension SIMD4 where Scalar: BinaryFloatingPoint {
    
    // Floating point components
    var red: Scalar   { x }
    var green: Scalar { y }
    var blue: Scalar  { z }
    var alpha: Scalar { w }
    
    /// Return red component as UInt8
    var redi: UInt8   { UInt8(x * 255.0) }
    
    /// Return green component as UInt8
    var greeni: UInt8 { UInt8(y * 255.0) }
    
    /// Return blue component as UInt8
    var bluei: UInt8  { UInt8(z * 255.0) }
    
    /// Return alpha component as UInt8
    var alphai: UInt8 { UInt8(w * 255.0) }
    
    public init(_ x: UInt8, _ y: UInt8, _ z: UInt8, _ w: UInt8) {
        self.init(Scalar(x) / 255.0, Scalar(y) / 255.0, Scalar(z) / 255.0, Scalar(w) / 255.0)
    }
    
    public init(_ v: SIMD4<UInt8>) {
        self.init(v.x, v.y, v.z, v.w)
    }

}
