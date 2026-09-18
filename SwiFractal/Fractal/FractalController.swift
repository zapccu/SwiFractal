//
//  FractalController.swift
//  SwiFractal
//
//  Created by Dirk Braner on 21.06.26.
//

import SwiftUI
import SwiftMPx
import ParSetKit


private struct SendableRawPointer: @unchecked Sendable {
    let ptr: UnsafeMutableRawPointer
}

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

    /// Read access to settings
    let settings = AppSettings.shared
    
    /// Image resolution without oversampling
    var resolution: CGSize
    
    /// Initial fractal dimensions (always MPFloat)
    var initialDimensions: FractalDimensions<MPFloat>
    
    /// Current fractal dimensions (always MPFloat)
    var dimensions: FractalDimensions<MPFloat>
    
    /// Selection
    var selection: Selection = Selection(fromMidPoint: false, keepAspectRatio: true)
    
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
    init() {
        let mandelbrot = Mandelbrot<Double>()
        self.resolution = settings.resolution
        self.initialDimensions = Mandelbrot<Double>.defaultDimensions.asMPFloat
        self.dimensions = Mandelbrot<Double>.defaultDimensions.asMPFloat
        self.kind = .mandelbrotDP(mandelbrot)
        self.fractal = mandelbrot
    }
    
    /// Clear calculation results
    func clearResults() {
        image = nil
        result = nil
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
        
        // Reset resolution to default
        resolution = settings.resolution
        
        // Fit dimensions or image size
        if fit == .fitToImageSize {
            fractal.fitDimensionsToImageSize(resolution: resolution)
        }
        else if fit == .fitToFractalSize {
            resolution = fractal.fitImageSizeToDimensions(resolution: resolution)
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
    /// - Parameter state: Calculation state
    func endCalculation(_ state: CalculationState) {
        isCalculating = false
        endTime = clock.now
        calculationTime = endTime - startTime
        calcState = state
    }
    
    /// Calculate fractal
    /// - Parameter method: Calculation method
    /// - Returns: Calculation state
    func calculate(method: CalculationMethod) async -> CalculationState {
        let (st, result) = await fractal.calculate(method: method, resolution: resolution)
        if result != nil {
            self.result = result!
            self.histogram = Histogram(result: result!, maxValue: fractal.getLimits().iterations)
        }
        return st
    }
    
 
    /// Draw results into graphics
    func drawResultSet() async {
        guard let result = result, let histogram = histogram else {
            debugPrint("No results to draw")
            return
        }
        
        // Measure drawing time
        let time1: ContinuousClock.Instant = .now
        
        let size = ISize(width: Int(resolution.width) * dimensions.oversampling, height: Int(resolution.height) * dimensions.oversampling)
        let limits = fractal.getLimits()
        let lightning = Lightning(fractal.getLightningParameters())
        
        // Create a color mapper
        let mapper = ColorMapper(colorParameters: fractal.getColorParameters(), limits: limits, histogram: histogram, lightning: lightning)
        
        // Create a graphics device
        let graphics = ImageGraphics(frameSize: resolution, size: size)

        image = graphics.beginDraw {
            graphics.clear(color: .blue)
            
            var byteOffset = 0
            var currentResult = result.grid[0]
            var color = mapper.mapColor(result: currentResult)
            //var color = mapper.mapResult(result: currentResult)
            var pixelCount = 1

            for r in result.grid {
                if r == currentResult {
                    pixelCount += 1
                    continue
                }
                currentResult = r
                let newColor = mapper.mapColor(result: r)
                //let newColor = mapper.mapResult(result: r)
                if newColor != color {
                    byteOffset = graphics.setPixels(fromByteOffset: byteOffset, count: pixelCount,
                                                    color: color, indexSize: graphics.indexSize)
                    color = newColor
                    pixelCount = 1
                }
                else {
                    pixelCount += 1
                }
            }
            _ = graphics.setPixels(fromByteOffset: byteOffset, count: pixelCount, color: color, indexSize: graphics.indexSize)
            
            // Measure drawing time
            let time2: ContinuousClock.Instant = clock.now
            let duration: Duration = time2 - time1
            let strDuration = duration.formatted(
                .time(pattern: .hourMinuteSecond(
                    padHourToLength: 2, fractionalSecondsLength: 3)
                )
            )
            debugPrint("Drawing time \(strDuration)")
            
            return graphics.cgImage
        }
    }

    /// Draw calculation result parallel.
    /// - Note: This is slower than drawing results sequentially
    func drawResultSetParallel() async {
        guard let result = result, let histogram = histogram else {
            debugPrint("No results to draw")
            return
        }

        let time1: ContinuousClock.Instant = .now

        let size = ISize(width: Int(resolution.width) * dimensions.oversampling,
                          height: Int(resolution.height) * dimensions.oversampling)
        let limits = fractal.getLimits()
        let lightning = Lightning(fractal.getLightningParameters())
        let mapper = ColorMapper(colorParameters: fractal.getColorParameters(),
                                  limits: limits, histogram: histogram, lightning: lightning)
        let graphics = ImageGraphics(frameSize: resolution, size: size)

        image = graphics.beginDrawParallel { base, indexSize in
            graphics.clear(color: .blue)

            let totalCount = result.grid.count
            let coreCount = ProcessInfo.processInfo.activeProcessorCount
            let oversubscriptionFactor = 2
            let targetChunkCount = coreCount * oversubscriptionFactor
            let chunkSize = max(1, (totalCount + targetChunkCount - 1) / targetChunkCount)
            let chunkCount = (totalCount + chunkSize - 1) / chunkSize
            debugPrint("Concurrent iterations (chunked): \(chunkCount)")

            let sendableBase = SendableRawPointer(ptr: base)

            DispatchQueue.concurrentPerform(iterations: chunkCount) { chunkIndex in
                let start = chunkIndex * chunkSize
                let end = min(start + chunkSize, totalCount)
                guard start < end else { return }

                // byteOffset ist NICHT kumulativ über den ganzen Grid-Verlauf,
                // sondern direkt aus dem Chunk-Start berechenbar -> Chunks sind
                // vollkommen unabhängig voneinander, keine Cross-Chunk-Dependency.
                var byteOffset = start * indexSize
                var currentResult = result.grid[start]
                //var color = mapper.mapResult(result: currentResult)
                var color = mapper.mapColor(result: currentResult)
                var pixelCount = 1

                for i in (start + 1)..<end {
                    let r = result.grid[i]
                    if r == currentResult {
                        pixelCount += 1
                        continue
                    }
                    currentResult = r
                    //let newColor = mapper.mapResult(result: r)
                    let newColor = mapper.mapColor(result: r)
                    if newColor != color {
                        byteOffset = ImageGraphics.setPixels(base: sendableBase.ptr,
                                                             fromByteOffset: byteOffset, count: pixelCount,
                                                             color: color, indexSize: indexSize)
                        color = newColor
                        pixelCount = 1
                    } else {
                        pixelCount += 1
                    }
                }
                _ = ImageGraphics.setPixels(base: sendableBase.ptr,
                                        fromByteOffset: byteOffset, count: pixelCount,
                                        color: color, indexSize: indexSize)
            }
        }

        let time2: ContinuousClock.Instant = .now
        let duration = time2 - time1
        let strDuration = duration.formatted(
            .time(pattern: .hourMinuteSecond(padHourToLength: 2, fractionalSecondsLength: 3))
        )
        debugPrint("Drawing time \(strDuration)")
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
