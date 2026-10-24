//
//  Coordinates.swift
//  SwiFractal
//
//  Created by Dirk Braner on 13.04.26.
//
//  Types:
//
//    ISize
//    IPoint
//    IRect
//

import SwiftUI

///
/// Point with integer coordinates
///
struct IPoint {
    var x: Int
    var y: Int
    
    static let zero = IPoint(x: 0, y: 0)
  
    /// Returns IPoint as CGPoint
    var cgPoint: CGPoint { CGPoint(x: x, y: y) }
    
    /// Initialize point from CGPoint
    init(point: CGPoint) {
        self.x = Int(point.x)
        self.y = Int(point.y)
    }
    
    /// Initialize point with integer coordinates
    init (x: Int, y: Int) {
        self.x = x
        self.y = y
    }
}

extension CGPoint {
    
    /// Initialize CGPoint from IPoint
    init(point: IPoint) {
        self.init(x: point.x, y: point.y)
    }
    
}

///
/// Size with integer coordinates
///
struct ISize {
    var width: Int
    var height: Int
    
    /// Return ISize as CGSize
    var cgSize: CGSize { CGSize(width: width, height: height) }
    
    init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }
    
    init(size: CGSize) {
        self.width = Int(size.width)
        self.height = Int(size.height)
    }
    
    static func == (lhs: ISize, rhs: ISize) -> Bool {
        lhs.width == rhs.width && lhs.height == rhs.height
    }
    
    static func != (lhs: ISize, rhs: ISize) -> Bool {
        !(lhs == rhs)
    }

}

extension CGSize {
    
    /// Initialize CGSize from ISize
    init(size: ISize) {
        self.init(width: size.width, height: size.height)
    }
    
}

///
/// Aspect ratio mode
///
enum AspectRatioMode {
    case ignoreAspectRatio
    case fitToImageSize
    case fitToFractalSize
}

///
/// Rectangle with integer coordinates
///
struct IRect {
    var origin: IPoint
    var width: Int
    var height: Int
    
    /// Return point at lower right corner of rectangle
    var destination: IPoint {
        IPoint(x: origin.x + width, y: origin.y + height)
    }
    
    /// Return size of rectangle
    var size: ISize {
        ISize(width: width, height: height)
    }
    
    /// Return IRect as CGRect
    var cgRect: CGRect {
        CGRect(x: origin.x, y: origin.y, width: width, height: height)
    }
    
    /// Return size of rectangle as CGSize
    var cgSize: CGSize {
        CGSize(width: width, height: height)
    }

    init(rect: CGRect) {
        self.origin = IPoint(point: rect.origin)
        self.width = Int(rect.width)
        self.height = Int(rect.height)
    }
    
    init(origin: IPoint, width: Int, height: Int) {
        self.origin = origin
        self.width = width
        self.height = height
    }
    
    init(from: IPoint, to: IPoint) {
        self.origin = from
        self.width = to.x - from.x
        self.height = to.y - from.y
    }
}

extension CGRect {
    
    /// Initialize CGRect from IRect
    init(rect: IRect) {
        self.init(origin: rect.origin.cgPoint, size: rect.cgSize)
    }
    
}
