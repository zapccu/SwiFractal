//
//  FractalController.swift
//  SwiFractal
//
//  Created by Dirk Braner on 21.06.26.
//

import SwiftUI
import SwiftMPx
import ParSetKit


/// Calculation state
/// - idle: No calculation is running
/// - completed: Calculation finished successfully
/// - inProgress: Calculation is running
/// - cancelled: Calculation was cancelled
/// - error: Calculation failed with an error
/// - Parameters:
///   - msg: Optional message to display
enum CalculationState {
    case idle(String = "Idle")
    case completed(String = "Completed")
    case inProgress(String = "In progress")
    case cancelled(String = "Cancelled")
    case error(String = "Unknown error")
    
    var message: String {
        switch self {
        case .idle(let msg), .completed(let msg), .inProgress(let msg), .cancelled(let msg), .error(let msg):
            return msg
        }
    }
}

///
/// Enum for fractal kinde ID
///
enum FractalKindID: String, CaseIterable {
    case mandelbrot = "Mandelbrot"
    case julia = "Julia"
}

///
/// Enum for fractal kind
/// Supported types:
/// - mandelbrotDP: Mandelbrot set with double precision
/// - mandelbrotAP: Mandelbrot set with arbitrary precision
/// - juliaDP: Julia set with double precision
/// - juliaAP: Julia set with arbitrary precision
///
@MainActor
enum FractalKind {
    case mandelbrotDP(Mandelbrot<Double>)
    case mandelbrotAP(Mandelbrot<MPFloat>)
    case juliaDP(Julia<Double>)
    case juliaAP(Julia<MPFloat>)
}

///
/// Fractal controller class
///
@Observable
@MainActor
class FractalController {

    /// The fractal kind
    var kind: FractalKind

    /// The fractal
    var fractal: any FractalProtocol
    
    /// Image resolution without oversampling
    var resolution: CGSize
    
    /// Initial fractal dimensions (always MPFloat)
    var initialDimensions: FractalDimensions<MPFloat>
    
    /// Current fractal dimensions (always MPFloat)
    var dimensions: FractalDimensions<MPFloat>
    
    /// Selection
    var selection: Selection = Selection(fromMidPoint: false, keepAspectRatio: true)
    
    /// Rendered image
    var image: CGImage?
    
    /// Zoomed image
    var zoomedImage: CGImage?
    
    /// Flag for signalling zoomed image
    @ObservationIgnored var isImageZoomed: Bool = false

    /// Flag for ongoing calculation
    @ObservationIgnored var isCalculating: Bool = false
    
    /// Calculation state
    @ObservationIgnored var calcState: CalculationState = .idle()

    /// Clock for time measurement
    @ObservationIgnored let clock: ContinuousClock = ContinuousClock()

    // Timings
    @ObservationIgnored var startTime: ContinuousClock.Instant = .now
    @ObservationIgnored var endTime: ContinuousClock.Instant = .now
    @ObservationIgnored var calculationTime: Duration = .zero
    
    /// Return true if dimensions changed
    var dimensionsChanged: Bool {
        dimensions != initialDimensions
    }
    
    /// Return true if any parameters changed
    var parametersChanged: Bool {
        fractal.hasChanges || dimensionsChanged
    }
    
    /// Return calculation time as formatted String
    var formattedCalculationTime: String {
        calculationTime.formatted(
            .time(pattern: .hourMinuteSecond(
                padHourToLength: 2, fractionalSecondsLength: 3)
            )
        )
    }
    
    /// Return CPU count (currently limitted to 4)
    var cpuCount: Int {
        min(ProcessInfo.processInfo.processorCount, 4)
    }

    /// Initialize fractal controller
    /// - Parameter resolution: Image resolution
    init(resolution: CGSize) {
        let mandelbrot = Mandelbrot<Double>()
        self.resolution = resolution
        self.initialDimensions = Mandelbrot<Double>.defaultDimensions.asMPFloat
        self.dimensions = Mandelbrot<Double>.defaultDimensions.asMPFloat
        self.kind = .mandelbrotDP(mandelbrot)
        self.fractal = mandelbrot
    }
    
    /// Set new fractal object and adjust image resolution or fractal dimensions depending
    /// on specified aspect ratio mode.
    /// - Parameters:
    ///   - kind: New fractal
    ///   - fit: Aspect ratio mode. Default = .ignoreAspectRatio
    func setFractal(kind: FractalKind, fit: AspectRatioMode = .ignoreAspectRatio) {
        self.kind = kind
        
        switch kind {
        case .mandelbrotDP(let f):
            self.fractal = f
        case .mandelbrotAP(let f):
            self.fractal = f
        case .juliaDP(let f):
            self.fractal = f
        case .juliaAP(let f):
            self.fractal = f
        }
        
        if fit == .fitToImageSize {
            fractal.fitDimensionsToImageSize(resolution: resolution)
        }
        else if fit == .fitToFractalSize {
            resolution = fractal.fitImageSizeToDimensions(resolution: resolution)
        }
        
        // Store dimensions
        dimensions = fractal.getDimensions()
        initialDimensions = dimensions
        
        // Add or update color table
        FractalAppData.addColorTable(colorTable: fractal.getColorTable())
    }
    
    /// Undo parameter changes
    func undo() {
        fractal.undo()
        self.dimensions = fractal.getDimensions()
    }
    
    /// Apply new parameters. Create new fractal object if precision is changing between Double and MPFloat
    func applyNewParameters() {
        // Detect rendering strategy and required precision
        let (strategy, precision) = RenderPrecisionStrategy.getRenderStrategy(
            resolution: resolution, size: dimensions.minSize
        )
        
        switch kind {
        case .mandelbrotDP(let f):
            if strategy == .double {
                // Keep Double precision
                f.FP.dimensions = dimensions.toDouble()
                f.FP.commit()
                initialDimensions = dimensions
            }
            else {
                // Switch to arbitrary precision
                var p = f.FP.current.toMPFloat(precision: precision.bits)
                p.dimensions = dimensions.toMPFloat(precision: precision.bits)
                setFractal(kind: .mandelbrotAP(Mandelbrot(mandelbrotParameters: p)))
            }
            
        case .mandelbrotAP(let f):
            if strategy == .double {
                // Switch to Double precision
                var p = f.FP.current.toDouble()
                p.dimensions = dimensions.toDouble()
                setFractal(kind: .mandelbrotDP(Mandelbrot(mandelbrotParameters: p)))
            }
            else {
                // Keep arbitrary precision (optionally increase number of precision bits)
                f.FP.dimensions = dimensions.toMPFloat(precision: precision.bits)
                f.FP.commit()
                initialDimensions = dimensions
            }

        case .juliaDP(let f):
            if strategy == .double {
                // Keep double precision
                f.FP.dimensions = dimensions.toDouble()
                f.FP.commit()
                initialDimensions = dimensions
            }
            else {
                // Switch to arbitrary precision
                var p = f.FP.current.toMPFloat(precision: precision.bits)
                p.dimensions = dimensions.toMPFloat(precision: precision.bits)
                setFractal(kind: .juliaAP(Julia(juliaParameters: p)))
            }

        case .juliaAP(let f):
            if strategy == .double {
                // Switch to double precision
                var p = f.FP.current.toDouble()
                p.dimensions = dimensions.toDouble()
                setFractal(kind: .juliaDP(Julia(juliaParameters: p)))
            }
            else {
                // Keep arbitrary precision (optionally increase number of precision bits)
                f.FP.dimensions = dimensions.toMPFloat(precision: precision.bits)
                f.FP.commit()
                initialDimensions = dimensions
            }
        }
    }
    
    func handleSelection() -> some Gesture {
        return DragGesture(minimumDistance: 0)
            .onChanged { event in
                self.selection.onChanged(event, CGRect(origin: .zero, size: self.resolution))
            }
            .onEnded{ event in
                self.selection.onEnded(event, CGRect(origin: .zero, size: self.resolution))
                let area = self.selection.getArea(flipped: true, height: Int(self.resolution.height))
                let dimensionsPrecision = self.dimensions.zoomArea(area: area, resolution: self.resolution)
                
                switch dimensionsPrecision {
                case .double(let dim):
                    self.dimensions = dim.asMPFloat
                case .mpfloat(let dim):
                    self.dimensions = dim
                }
                
                self.selection.reset()
                self.zoomImage(area: area)
            }
    }

    /// Start of calculation. Initialize timer
    func beginCalculation() {
        startTime = clock.now
        isCalculating = true
        isImageZoomed = false
        calcState = .inProgress()
    }
    
    /// End of calculation. Measure calculation time
    func endCalculation(_ state: CalculationState) {
        isCalculating = false
        endTime = clock.now
        calculationTime = endTime - startTime
        calcState = state
    }
    
    /// Magnify area of current image
    func zoomImage(area: CGRect) {
        zoomedImage = image?.zoomImage(area: area, frameSize: resolution)
        isImageZoomed = true
    }
    
    /// Map drawing canvas point to fractal coordinates. Change orientation of Y-axis (0, 0 in lower left corner)
    /// - Parameter point: Point within drawing canvas
    /// - Returns: Tuple of String values: (CanvasX, CanvasY, FractalX, FractalY)
    func mapPointFormatted(_ point: CGPoint) -> (String, String, String, String) {
        let posX = Int(point.x)
        let posY = Int(resolution.height - point.y)
        let (x, y) = dimensions.mapPoint(point, resolution: resolution, oversampling: 1)
        return (String(posX), String(posY), x.toString(), y.toString())
    }
    
}
