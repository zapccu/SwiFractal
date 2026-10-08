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
    
    /// Selection state
    /// - noSelection: Nothing selected
    /// - pointSelected: Point selected
    /// - areaSelected: Area selected
    /// - movingSelection: Moving selected area
    enum SelectState: Int {
        case noSelection = 0        // No selection
        case selecting = 1          // Ongoing selection
        case pointSelected = 2      // Point selected
        case areaSelected = 3       // Area selected
        case movingSelection = 4    // Moving selected area
    }
    
    /// Return selected point. Consider flipping of Y-axis
    var selectedPoint: CGPoint {
        return flip ? CGPoint(x: area.origin.x, y: resolution.height - area.origin.y) : area.origin
    }
    
    /// Return selected area. Consider flipping of Y-axis
    var selectedArea: CGRect {
        // Assumption: area is standardized
        if flip {
            let origin = CGPoint(x: selectedPoint.x, y: selectedPoint.y - area.size.height)
            return CGRect(origin: origin, size: area.size)
        }
        else {
            return area
        }
    }
    
    /// Return selected area as String
    var areaString: String {
        let rect = IRect(rect: selectedArea)
        return "X: \(rect.origin.x) Y: \(rect.origin.y) W: \(rect.width) H: \(rect.height)"
    }
    
    /// Return true if point is selected
    var pointSelected: Bool {
        state == .pointSelected
    }
    
    /// Return true if area is selected and size is greater than zero and size is smaller then resolution
    var areaSelected: Bool {
        state == .areaSelected && selectedArea.size != .zero && selectedArea.size != resolution
    }
    
    /// Return true if either point or area is selected
    var anySelected: Bool {
        pointSelected || areaSelected
    }
    
    /// Selection state
    var state: SelectState = .noSelection
    
    /// Current standardized area without flipping
    private var area: CGRect = .zero
    
    /// Resolution of frame
    @ObservationIgnored let resolution: CGSize
    
    /// Clipping rectangle
    @ObservationIgnored var clipRect: CGRect
    
    /// Minimum size of the selected area. If size of current selection is smaller
    /// the selection is treated as a point selection
    @ObservationIgnored let minAreaSize: CGFloat
    
    /// Selected area is growing in all directions from the starting point when dragging
    @ObservationIgnored let fromMidPoint: Bool
    
    /// Keep aspect ratio of underlying canvas when dragging
    @ObservationIgnored let keepAspectRatio: Bool
    
    /// Clip to resolution
    @ObservationIgnored let clip: Bool
    
    /// Flip Y coordinates
    @ObservationIgnored let flip: Bool
    
    /// Selection rectangle currently drawn on canvas
    @ObservationIgnored var drawnRect: CGRect = .zero
    
    /// Difference between mouse moint and area.origin when moving selected area
    @ObservationIgnored var deltaX: CGFloat = 0.0
    @ObservationIgnored var deltaY: CGFloat = 0.0

    /// Init selection
    init(resolution: CGSize, minAreaSize: CGFloat = 2.0, fromMidPoint: Bool = false,
         keepAspectRatio: Bool = true, clip: Bool = true, flip: Bool = true) {
        self.resolution      = resolution
        self.clipRect        = CGRect(origin: .zero, size: resolution)
        self.minAreaSize     = minAreaSize
        self.fromMidPoint    = fromMidPoint
        self.keepAspectRatio = keepAspectRatio
        self.clip            = clip
        self.flip            = flip
    }
    
    /// Reset selection
    func reset() {
        area  = .zero
        state = .noSelection
    }
    
    /// Draw rectangle marking the selected area
    /// - Parameter graphics: Canvas graphics
    func draw(_ graphics: CanvasGraphics) {
        // Clear existing rectangle
        if drawnRect != .zero {
            let blendMode = graphics.setBlendMode(.clear)
            graphics.drawRect(rect: IRect(rect: drawnRect), color: .red)
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
                graphics.drawRect(rect: IRect(rect: area), color: .red)
                drawnRect = area
            }
            else {
                graphics.drawRect(rect: IRect(rect: area), color: .red)
                drawnRect = area
            }
        }
    }

    /// Mouse button pressed and/or mouse dragged
    /// - Parameter event: Mouse event
    func onChanged(_ event: DragGesture.Value) {
        guard !clip || clipRect.contains(event.location) else { return }

        if area == .zero {
            // Start new selection
            debugPrint("New selection started at: \(event)")
            area = CGRect(origin: event.location, size: .zero)
            state = .selecting
        }
        else if state == .movingSelection {
            // Move selected area
            let x = min(max(0, event.location.x - deltaX) + area.width, resolution.width) - area.width
            let y = min(max(0, event.location.y - deltaY) + area.height, resolution.height) - area.height
            let newArea = CGRect(x: x, y: y, width: area.width, height: area.height)
            area = newArea.standardized
        }
        else if state == .areaSelected {
            if area.contains(event.location) {
                // Click inside current selection. Start moving selection
                state = .movingSelection
                self.deltaX = event.location.x - area.origin.x
                self.deltaY = event.location.y - area.origin.y
            }
            else {
                // Click outside current selection. Reset current selection
                debugPrint("Resetting selection")
                reset()
            }
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
            
            // Clip and standardize selected area
            area = clip ? clipRect.intersection(newArea.standardized) : newArea.standardized
        }
    }
    
    /// Dragging ended and/or mouse button released
    /// - Parameter event: Mouse event
    func onEnded(_ event: DragGesture.Value) {
        guard area != .zero else {
            state = .noSelection
            return
        }
        
        if area.width > minAreaSize && area.height > minAreaSize {
            state = .areaSelected
            area = clip ? clipRect.intersection(area.standardized) : area.standardized
            debugPrint("Area \(area)")
            debugPrint("Area selected \(selectedArea)")
        }
        else {
            state = .pointSelected
            debugPrint("Point selected: \(area.origin) \(selectedPoint)")
        }
    }
    
}
