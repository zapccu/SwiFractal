//
//  Selection.swift
//  SwiFractal
//
//  Created by Dirk Braner on 02.12.24.
//

import SwiftUI

///
/// Class for selecting a point or an area on a canvas
///
@Observable class Selection {
    enum SelectState: Int {
        case noSelection = 0
        case pointSelected = 1
        case areaSelected = 2
    }
    
    // Changing these variables will trigger an update of the selection view
    var area: CGRect = .zero
    var state: SelectState = .noSelection
    
    @ObservationIgnored let minAreaSize: CGFloat
    @ObservationIgnored let fromMidPoint: Bool          // Selected area is growing in all direction when dragging
    @ObservationIgnored let keepAspectRatio: Bool       // Keep aspect ratio of underlying canvas when dragging
    
    @ObservationIgnored var drawnRect: CGRect = .zero   // Selection rectangle cuurently drawn on canvas

    /// Init selection
    init(minAreaSize: CGFloat = 2.0, fromMidPoint: Bool = false, keepAspectRatio: Bool = false) {
        self.minAreaSize = minAreaSize
        self.fromMidPoint = fromMidPoint
        self.keepAspectRatio = keepAspectRatio
    }
    
    /// Draw rectangle marking the selected area
    func draw(_ graphics: CGGraphics) {
        graphics.setColor(.red)
        
        if drawnRect != .zero {
            // Clear existing rectangle
            let blendMode = graphics.setBlendMode(.clear)
            graphics.drawRect(drawnRect)
            _ = graphics.setBlendMode(blendMode)
            drawnRect = .zero
        }

        if area.width > minAreaSize && area.height > minAreaSize {
            // Draw new rectangle
            let aspectRatio = CGFloat(Float(graphics.width) / Float(graphics.height))
            if keepAspectRatio && aspectRatio != 1.0 {
                drawnRect = CGRect(origin: area.origin, size: CGSize(width: area.width, height: area.height * aspectRatio))
                graphics.drawRect(drawnRect)
            }
            else {
                graphics.drawRect(area)
                drawnRect = area
            }
        }
    }

    /// Mouse button pressed and/or mouse dragged
    func onChanged(_ event: DragGesture.Value, _ clipRect: CGRect = .zero) {
        guard clipRect.contains(event.location) else { return }
        
        if area == .zero {
            // Start new selection
            print("New selection started at: \(event)")
            area = CGRect(origin: event.location, size: .zero)
        }
        else if state == .pointSelected || (state == .areaSelected && !area.contains(event.location)) {
            // Reset selection
            print("Resetting selection")
            area = .zero
            state = .noSelection
        }
        else {
            // Mouse dragged, update selected area
            var newArea = area
            if fromMidPoint {
                // Selection is growing from point where dragging started in all directions
                let dx = abs(event.location.x - event.startLocation.x)
                let dy = abs(event.location.y - event.startLocation.y)
                let newOrigin = CGPoint(x: event.startLocation.x - dx, y: event.startLocation.y - dy)
                let newSize   = CGSize(width: dx * 2.0, height: dy * 2.0)
                newArea = CGRect(origin: newOrigin, size: newSize)
            }
            else {
                // Selection is growing in dragging direction
                newArea.size = CGSize(width: event.location.x - area.origin.x, height: event.location.y - area.origin.y)
            }
            
            area = clipRect.intersection(newArea)
        }
    }
    
    /// Dragging ended, mouse button released
    func onEnded(_ event: DragGesture.Value, _ clipRect: CGRect = .zero) {
        if area != .zero {
            if area.width > minAreaSize && area.height > minAreaSize {
                state = .areaSelected
                area = clipRect.intersection(area.standardized)
                print("Area selected: \(area)")
            }
            else {
                state = .pointSelected
                print("Point selected: \(area.origin)")
            }
        }
        else {
            state = .noSelection
        }
    }
    
}
