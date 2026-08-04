//
//  ComplexString.swift
//  SwiFractal
//
//  Created by Dirk Braner on 12.05.26.
//

import SwiftMPx

//
// Complex number with real and imaginary parts as String
//
struct ComplexString: Codable, Hashable {
    
    var real: String = "0"
    var imaginary: String = "0"
  
    init(_ real: String, _ imaginary: String = "0") {
        self.real = real
        self.imaginary = imaginary
    }
    
}

//
// Cast ComplexString to Cpx / Complex<Double>
//
extension Cplx {
    
    init?(_ complex: ComplexString) {
        self.init(complex.real, complex.imaginary)
    }
    
}

//
// Cast ComplexString to MPComplex
//
extension MPComplex {
    
    init?(_ complex: ComplexString, precision: Int = 128) {
        self.init(complex.real, complex.imaginary, precision: precision)
    }
    
}
