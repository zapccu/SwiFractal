//
//  CursorLocation.swift
//  SwiFractal
//
//  Created by Dirk Braner on 24.09.26.
//

import Foundation
import SwiftUI


///
/// Handle mouse pointer movement
///
final class CursorLocation {
    
    /// Frame size
    var resolution: CGSize
    
    /// Flip Y-axis
    let flip: Bool
    
    /// Current mouse pointer location considering flipping
    var location: CGPoint {
        return flip ? CGPoint(x: physicalLocation.x, y: resolution.height - physicalLocation.y) : physicalLocation
    }
    
    /// Screen coordinates without flipping
    var physicalLocation: CGPoint = .zero
    
    init(resolution: CGSize, flip: Bool = true) {
        self.resolution = resolution
        self.flip = flip
    }
    
    /// Called when mouse is moved. Update current location.
    /// - Parameter phase: Moving phase
    func onHover(phase: HoverPhase) {
        switch phase {
        case .active(let location):
            self.physicalLocation = location
        case .ended:
            // Pointer outside of view
            self.physicalLocation = .zero
        }
    }
}
