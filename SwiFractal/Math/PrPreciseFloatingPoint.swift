//
//  PrPreciseFloatingPoint.swift
//  SwiFractal
//
//  Created by Dirk Braner on 08.05.26.
//

//
// PreciseFloatingPoint protocol
//
protocol PreciseFloatingPoint: BasicCalculations {
    var precision: Int32 { get }

    init(_ value: Double, precision: Int32)
}


extension MPFloat : PreciseFloatingPoint {
    
}
