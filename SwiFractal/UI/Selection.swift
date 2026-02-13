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
        case noSelection = 0    // No selection
        case pointSelected = 1  // Point selected
        case areaSelected = 2   // Area selected
    }
    
    // Changing these variables will trigger an update
    // of the selection view
    var area: CGRect = .zero                            // Selected area
    var state: SelectState = .noSelection               // Selection state
    
    // Changes on the following variables are ignored
    // by the view update process
    @ObservationIgnored let minAreaSize: CGFloat        // Minimum size of the selected area
    @ObservationIgnored let fromMidPoint: Bool          // Selected area is growing in all directions from the starting point when dragging
    @ObservationIgnored let keepAspectRatio: Bool       // Keep aspect ratio of underlying canvas when dragging
    @ObservationIgnored var drawnRect: CGRect = .zero   // Selection rectangle currently drawn on canvas

    /// Init selection
    init(minAreaSize: CGFloat = 2.0, fromMidPoint: Bool = false, keepAspectRatio: Bool = false) {
        self.minAreaSize     = minAreaSize
        self.fromMidPoint    = fromMidPoint
        self.keepAspectRatio = keepAspectRatio
    }
    
    /// Reset selection
    func reset() {
        area  = .zero
        state = .noSelection
    }
    
    /// Return selected point
    func getPoint(flipped: Bool = false, height: Int = 0) -> CGPoint {
        return flipped && height > 0 ? CGPoint(x: area.minX, y: CGFloat(height) - area.minY - 1) : area.origin
    }
    
    /// Return selected area
    func getArea(flipped: Bool = false, height: Int = 0) -> CGRect {
        if flipped && height >= Int(area.height) {
            return CGRect(x: area.minX, y: CGFloat(height) - area.maxY, width: area.width, height: area.height)
        }
        else {
            return area
        }
    }
    
    /// Draw rectangle marking the selected area
    func draw(_ graphics: CanvasGraphics) {
        graphics.setColor(.red)

        // Clear existing rectangle
        if drawnRect != .zero {
            let blendMode = graphics.setBlendMode(.clear)
            graphics.drawRect(drawnRect)
            _ = graphics.setBlendMode(blendMode)
            drawnRect = .zero
        }

        // Draw selection rectangle
        if area.width > minAreaSize && area.height > minAreaSize {
            // Calculate aspect ratios
            let screenAR = CGFloat(Float(graphics.width) / Float(graphics.height))
            let selectAR = CGFloat(Float(area.width) / Float(area.height))
            
            // Adjust selected area to keep aspect ratio of view
            if keepAspectRatio && selectAR != screenAR {
                if selectAR < 1 {
                    area = CGRect(origin: area.origin, size: CGSize(width: area.height * screenAR, height: area.height))
                }
                else {
                    area = CGRect(origin: area.origin, size: CGSize(width: area.width, height: area.width / screenAR))
                }
                graphics.drawRect(area)
                drawnRect = area
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
