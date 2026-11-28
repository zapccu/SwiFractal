//
//  FractalController.swift
//  SwiFractal
//
//  Created by Dirk Braner on 21.06.26.
//

import SwiftUI
import SwiftMPx
import ParSetKit


///
/// Enum for fractal kind ID
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

    /// Read access to settings
    let settings = AppSettings.shared
    
    /// Image resolution without oversampling
    var resolution: CGSize {
        didSet {
            self.selection = Selection(resolution: resolution, flip: true)
            self.cursorLocation = CursorLocation(resolution: resolution, flip: true)
        }
    }
    
    /// Initial fractal dimensions (always MPFloat)
    var initialDimensions: FractalDimensions<MPFloat>
    
    /// Current fractal dimensions (always MPFloat)
    var dimensions: FractalDimensions<MPFloat>
    
    /// Mouse pointer position
    var cursorLocation: CursorLocation
    
    /// Area or point selection
    var selection: Selection
    
    /// Calculation progress
    let progress = CalculationProgress()
    
    /// Status view information
    var info: Info
    
    /// Calculation result
    @ObservationIgnored var result: Matrix<MandelbrotResult>?
    
    /// Histogram
    @ObservationIgnored var histogram: Histogram?
    
    /// Rendered image
    var image: CGImage?
    
    /// Zoomed image
    var zoomedImage: CGImage?
    
    /// Display image spherical
    var isSphericalDisplay: Bool = false
    
    /// Flag for signalling zoomed image
    @ObservationIgnored var isImageZoomed: Bool = false

    /// Show calculation progress
    var showsProgress = false
    
    /// Calculation progress
    var progressFraction: Double = 0
    
    /// Calculation pass
    var calculationPass: Int = 0
    
    /// Flag for ongoing calculation
    var isCalculating: Bool = false
    
    /// Calculation state
    /// State of the last calculation (shown in status bar)
    @ObservationIgnored var calcInfo: CalculationInfo = CalculationInfo(state: .idle)
    
    /// Information about the calculation result in `result` (state completed). Unlike calcInfo it
    /// is not changed by failed or cancelled calculations, which don't replace the result.
    @ObservationIgnored var resultInfo: CalculationInfo = CalculationInfo(state: .idle)
    
    /// Calculation method used by the last calculation (automatic resolved)
    @ObservationIgnored var lastMethod: CalculationMethod = .sequential

    /// Clock for time measurement
    @ObservationIgnored let clock: ContinuousClock = ContinuousClock()

    // Timings
    @ObservationIgnored var startTime: ContinuousClock.Instant = .now
    @ObservationIgnored var endTime: ContinuousClock.Instant = .now
    @ObservationIgnored var calculationTime: Duration = .zero
    @ObservationIgnored var drawingTime: Duration = .zero
    
    /// Return true if dimensions changed
    var dimensionsChanged: Bool {
        dimensions != initialDimensions
    }
    
    /// Return true if any parameters changed
    var parametersChanged: Bool {
        fractal.hasChanges || dimensionsChanged
    }
    
    /// Return screen location as formatted String
    var fmtScreenLocation: String {
        String(format: "X: %d, Y: %d", Int(cursorLocation.location.x), Int(cursorLocation.location.y))
    }
    
    /// Return complex location as formatted string
    var fmtComplexLocation: String {
        let (r, i) = dimensions.mapPoint(cursorLocation.location, resolution: resolution, oversampling: 1)
        return "C: \(MPComplex(r, i).toString(digits: 5))"
    }
    
    /// Return calculation time as formatted String
    var fmtCalculationTime: String {
        calculationTime.formatted(
            .time(pattern: .hourMinuteSecond(padHourToLength: 2, fractionalSecondsLength: 3))
        )
    }
    
    /// Return drawing time as formatted string
    var fmtDrawingTime: String {
        drawingTime.formatted(
            .time(pattern: .hourMinuteSecond(padHourToLength: 2, fractionalSecondsLength: 3))
        )
    }
    
    /// Initialize fractal controller
    init() {
        let mandelbrot = Mandelbrot<Double>()
        self.resolution = settings.resolution
        self.initialDimensions = Mandelbrot<Double>.defaultDimensions.asMPFloat
        self.dimensions = Mandelbrot<Double>.defaultDimensions.asMPFloat
        self.kind = .mandelbrotDP(mandelbrot)
        self.fractal = mandelbrot
        self.selection = Selection(resolution: settings.resolution, flip: true)
        self.info = Info()
        self.cursorLocation = CursorLocation(resolution: settings.resolution, flip: true)
    }
    
    /// Clear calculation results
    func clearResults() {
        image = nil
        result = nil
        calcInfo = CalculationInfo(state: .idle)
        resultInfo = CalculationInfo(state: .idle)
        histogram = nil
    }
    
    /// Set new fractal object and adjust image resolution or fractal dimensions depending
    /// on specified aspect ratio mode.
    /// Reset image, result and histogram.
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
        
        // Clear current calculation results
        clearResults()
        
        // Reset resolution to default settings
        resolution = settings.resolution
        
        // Fit dimensions or image size
        if fit == .fitToImageSize {
            // Fit fractal dimensions to resolution
            fractal.fitDimensionsToImageSize(resolution: settings.resolution)
        }
        else if fit == .fitToFractalSize {
            // Fit resolution to fractal dimensions
            resolution = fractal.fitImageSizeToDimensions(resolution: settings.resolution)
        }
        
        // Store dimensions of new fractal in fractal controller
        dimensions = fractal.getDimensions()
        initialDimensions = dimensions
        
        // Add or update coloring.
        let coloring = fractal.getColoring()
        FractalAppData.addColoring(coloring: coloring, name: coloring.coloringType.name)
    }
    
    /// Undo parameter changes
    func undo() {
        fractal.undo()
        self.dimensions = fractal.getDimensions()
    }
    
    /// Reset parameters
    func reset() {
        fractal.reset()
        // initialDimensions is updated by applyNewParameters(), so take the dimensions from the reset fractal
        self.dimensions = fractal.getDimensions()
        self.initialDimensions = self.dimensions
    }
    
    /// Apply new parameters. Create new fractal object if precision is changing between Double and MPFloat
    func applyNewParameters() {        
        // Detect rendering strategy and required precision
        let (strategy, precision) = dimensions.renderStrategy(resolution: resolution)
        
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
        
        selection.reset()
    }
    
    /// Zoom into selected area
    /// - Returns: true if zoomed in
    func zoomArea() {
        guard selection.areaSelected else { return }
        
        let dimensionsPrecision = self.dimensions.zoomArea(area: self.selection.selectedArea,
                                                           resolution: self.resolution)
        switch dimensionsPrecision {
        case .double(let dim):
            self.dimensions = dim.asMPFloat
        case .mpfloat(let dim):
            self.dimensions = dim
        }
    }
    
    /// Handle selection of view area
    /// - Returns: Drag gesture
    func handleSelection() -> some Gesture {
        return DragGesture(minimumDistance: 0)
            .onChanged { event in
                self.selection.onChanged(event)
                self.info.selectedArea = self.selection.areaString
            }
            .onEnded{ event in
                self.selection.onEnded(event)
                if self.selection.areaSelected {
                    ToastCenter.shared.show("Area selected", systemImage: "checkmark.circle.fill", actionTitle: "Apply") {
                        self.zoomArea()
                        self.applyNewParameters()
                    }
                }
            }
    }

    /// Start of calculation. Initialize timer
    func beginCalculation() {
        startTime = clock.now
        progressFraction = 0
        calculationPass = 0
        showsProgress = false
        isCalculating = true
        isImageZoomed = false
        calcInfo = CalculationInfo(state: .inProgress)
    }
    
    /// End of calculation. Measure calculation time
    func endCalculation() {
        isCalculating = false
        endTime = clock.now
        calculationTime = endTime - startTime
    }
    
    /// Calculate fractal
    /// - Parameter method: Calculation method
    /// - Returns: Calculation state
    /// Resolve calculation method .automatic depending on the required precision.
    ///
    /// - Metal (Metal64) if its 48 bit mantissa is sufficient and the GPU supports the
    ///   interior coloring mode
    /// - Double precision on CPU (parallel) if Double is sufficient
    /// - Perturbation if Double's exponent range is sufficient for the deltas (Mandelbrot only)
    /// - Arbitrary precision on CPU (parallel) otherwise
    ///
    /// Other methods are returned unchanged.
    /// - Parameter method: Selected calculation method
    /// - Returns: Calculation method to be used
    func resolveMethod(_ method: CalculationMethod) -> CalculationMethod {
        guard method == .automatic else { return method }
        
        let supported = fractal.getSupportedCalculationMethods()
        let (strategy, _) = dimensions.renderStrategy(resolution: resolution)
        
        // Interior coloring modes implemented in the Metal kernels
        let metalColorizeInside: [ColorizeInside] = [.defaultColor, .orbits, .fastOrbits]
        let colorizeInside = fractal.getColorParameters().colorizeInside
        
        if supported.contains(.metalcompute)
            && dimensions.isMetal64Sufficient(resolution: resolution)
            && metalColorizeInside.contains(colorizeInside) {
            return .metalcompute
        }
        
        switch strategy {
        case .double, .arbitrary:
            return supported.contains(.parallel) ? .parallel : .sequential
        case .perturbation:
            if supported.contains(.sequentialPerturbation) { return .sequentialPerturbation }
            return supported.contains(.parallel) ? .parallel : .sequential
        }
    }
    
    /// Calculate fractal
    ///
    /// calcInfo is always updated. The current result is replaced only if the calculation completed.
    /// - Parameter method: Calculation method, .automatic is resolved by resolveMethod()
    /// - Returns: True if calculation completed and a new result is available
    @discardableResult
    func calculate(method: CalculationMethod) async -> Bool {
        let poller = Task { [progress] in
            // Short calculations: Don't show the progress if calculation finished within 500 ms
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }

            // Almost finished (progress >= 80%) ? Don't show the progress
            guard progress.fraction < 0.8 else { return }

            self.progressFraction = progress.fraction
            self.calculationPass = progress.passes
            self.showsProgress = true

            while !Task.isCancelled {
                self.progressFraction = progress.fraction
                self.calculationPass = progress.passes
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
        defer {
            poller.cancel()
        }
        
        let resolvedMethod = resolveMethod(method)
        lastMethod = resolvedMethod
        
        let combinedResult = await fractal.calculate(method: resolvedMethod, resolution: resolution, progress: progress)
        
        // Always store the state, so errors and cancellation are reported
        self.calcInfo = combinedResult.info
        
        guard combinedResult.info.state.isSet(.completed), let newResult = combinedResult.result else {
            return false
        }
        
        self.result = newResult
        self.resultInfo = combinedResult.info
        self.histogram = Histogram(result: newResult, maxValue: fractal.getLimits().iterations)
        progressFraction = 1
        return true
    }
    
    /// Return statistical information for calculation result
    /// - Returns: Tuple (number of points inside Mandelbrot set, number of calculation errors)
    func getCalculationStats() -> (inside: Int, errors: Int) {
        guard let result else { return (-1, -1) }
        
        var inside: Int = 0
        var errors: Int = 0

        for r in result.grid {
            if r.flags.isSet(.inside) { inside += 1 }
            if r.flags.isSet(.error) { errors += 1 }
        }
        
        return (inside, errors)
    }
    
    /// Draw results into graphics
    func drawResultSet() async {
        // Check for existing calculation results
        guard self.result != nil, self.histogram != nil else {
            debugPrint("No results to draw")
            return
        }
        
        let colorParameters = fractal.getColorParameters()
        
        // Check if result contains stripe average values
        if colorParameters.colorizeMode == .stripes && self.resultInfo.extendedInfo.notSet(.stripes) {
            ToastCenter.shared.show("Results do not contain stripe data. Image must be recalculated", systemImage: "exclamationmark.triangle.fill")
            debugPrint("No stripe average values in results")
            return
        }
        
        // Check if result contains orbit length values
        if colorParameters.colorizeInside.isNone(of: [.defaultColor, .fastOrbits]) && self.resultInfo.extendedInfo.notSet(.orbits) {
            guard await ToastCenter.shared.showAndWait("Results do not contain orbit data. Image must be recalculated", actionTitle: "Calculate") else {
                return
            }
            
            // Recalculate with the method of the last calculation
            beginCalculation()
            let completed = await calculate(method: lastMethod)
            endCalculation()
            info.setState(currentAction: calcInfo.getMessage(), statusMessage: "Calculation time: \(fmtCalculationTime)")
            guard completed else { return }
        }
        
        // Bind results after a possible recalculation
        guard let result = self.result, let histogram = self.histogram else { return }
        
        // Measure drawing time
        let time1: ContinuousClock.Instant = .now
        
        let size = ISize(width: Int(resolution.width) * dimensions.oversampling, height: Int(resolution.height) * dimensions.oversampling)
        let limits = fractal.getLimits()
        let lightning = Lightning(fractal.getLightningParameters())
        
        // Create a color mapper
        let mapper = ColorMapper(colorParameters: colorParameters, limits: limits, histogram: histogram, lightning: lightning)
        
        // Create a graphics device
        let graphics = ImageGraphics(frameSize: resolution, size: size, flip: true)

        image = graphics.beginDraw {
            graphics.clear(color: .blue)
            
            for y in 0..<result.rows {
                var currentResult = result[y, 0]
                
                graphics.color = mapper.mapColor(result: currentResult)
                var pixelCount: Int = 1

                graphics.move(to: IPoint(x: 0, y: y))

                for x in 1..<result.cols {
                    let r = result[y, x]
                    if r == currentResult {
                        pixelCount += 1
                        continue
                    }
                    
                    currentResult = r
                    
                    let newColor = mapper.mapColor(result: r)
                    if newColor == graphics.color {
                        pixelCount += 1
                        continue
                    }
                    
                    graphics.drawHLine(count: pixelCount)
                    graphics.color = newColor
                    pixelCount = 1
                }
                
                graphics.drawHLine(count: pixelCount)
            }
            
            // Measure drawing time
            let time2: ContinuousClock.Instant = clock.now
            drawingTime = time2 - time1
            
            return graphics.cgImage
        }
    }
    
    /// Magnify area of current image
    func zoomImage(area: CGRect) {
        zoomedImage = image?.zoomImage(area: area, frameSize: resolution)
        isImageZoomed = true
    }
    
}
