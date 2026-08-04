//
//  HighPrec2.swift
//  SwiFractal
//
//  Created by Dirk Braner on 16.02.26.
//

import CMPFR

public class ComplexMPFloat {
    public let re: MPFloat
    public let im: MPFloat
    
    // Hilfsvariablen für interne Berechnungen (vermeidet Allokationen in der Schleife)
    private let tmp1: MPFloat
    private let tmp2: MPFloat

    public init(precision: Int32 = 128) {
        self.re = MPFloat("0", precision: precision)
        self.im = MPFloat("0", precision: precision)
        self.tmp1 = MPFloat("0", precision: precision)
        self.tmp2 = MPFloat("0", precision: precision)
    }
    
    /// Setzt die Werte von Real- und Imaginärteil
    public func set(re: String, im: String) {
        self.re.set(re)
        self.im.set(im)
    }

    public func set(from other: ComplexMPFloat) {
        self.re.set(from: other.re)
        self.im.set(from: other.im)
    }

    /// Berechnet Z = Z^2 + C (In-Place)
    /// Formel:
    /// newRe = re^2 - im^2 + cRe
    /// newIm = 2 * re * im + cIm
    public func iterateMandelbrot(cRe: MPFloat, cIm: MPFloat) {
        // tmp1 = re^2
        mpfr_mul(&tmp1.value, &re.value, &re.value, MPFR_RNDN)
        // tmp2 = im^2
        mpfr_mul(&tmp2.value, &im.value, &im.value, MPFR_RNDN)
        
        // Imaginärteil zuerst berechnen, bevor re überschrieben wird:
        // im = 2 * re * im + cIm
        mpfr_mul(&im.value, &re.value, &im.value, MPFR_RNDN)
        mpfr_mul_ui(&im.value, &im.value, 2, MPFR_RNDN)
        mpfr_add(&im.value, &im.value, &cIm.value, MPFR_RNDN)
        
        // Realteil berechnen: re = tmp1 - tmp2 + cRe
        mpfr_sub(&re.value, &tmp1.value, &tmp2.value, MPFR_RNDN)
        mpfr_add(&re.value, &re.value, &cRe.value, MPFR_RNDN)
    }
    
    /// Berechnet das Quadrat des Betrags (re^2 + im^2)
    /// Rückgabe als Double reicht für den Escape-Check (> 4.0) meist aus.
    public func magnitudeSquaredDouble() -> Double {
        mpfr_mul(&tmp1.value, &re.value, &re.value, MPFR_RNDN)
        mpfr_mul(&tmp2.value, &im.value, &im.value, MPFR_RNDN)
        mpfr_add(&tmp1.value, &tmp1.value, &tmp2.value, MPFR_RNDN)
        return mpfr_get_d(&tmp1.value, MPFR_RNDN)
    }
}

extension ComplexMPFloat {
    /// Berechnet den nächsten Schritt der Abweichung (Perturbation)
    /// - Parameters:
    ///   - delta: Die aktuelle Abweichung (in Double-Präzision)
    ///   - deltaC: Die Differenz des Pixel-C zum Referenz-C (in Double)
    /// - Returns: Die neue Abweichung für den nächsten Schritt
    public func perturbationStep(delta: (re: Double, im: Double), deltaC: (re: Double, im: Double)) -> (re: Double, im: Double) {
        // Holen der hochpräzisen Referenzwerte als Double
        let Zre = self.re.toDouble()
        let Zim = self.im.toDouble()
        
        // Formel: delta_next = 2 * Z * delta + delta^2 + deltaC
        // Zerlegt in Real- und Imaginärteil:
        // re_next = 2*(Zre*dre - Zim*dim) + (dre^2 - dim^2) + dcre
        // im_next = 2*(Zre*dim + Zim*dre) + (2*dre*dim) + dcim
        
        let dre = delta.re
        let dim = delta.im
        
        let nextRe = 2.0 * (Zre * dre - Zim * dim) + (dre * dre - dim * dim) + deltaC.re
        let nextIm = 2.0 * (Zre * dim + Zim * dre) + (2.0 * dre * dim) + deltaC.im
        
        return (re: nextRe, im: nextIm)
    }
}

extension ComplexMPFloat {
    /// Berechnet den geglätteten Iterationswert (Smooth Iteration Count)
    /// - Parameter iteration: Die ganzzahlige Iteration, bei der Z > 4.0 erreicht wurde
    /// - Returns: Ein Double-Wert für feine Farbübergänge
    public func smoothIterationCount(_ iteration: Int) -> Double {
        // Betrag |Z| = sqrt(re^2 + im^2) berechnen
        // Wir können direkt mit dem Quadrat arbeiten, um die Wurzel zu sparen:
        // log(log|Z|) = log(log(|Z|^2) / 2) = log(log(|Z|^2)) - log(2)
        
        let magSq = self.magnitudeSquaredDouble()
        
        if magSq <= 1.0 { return Double(iteration) } // Sicherheitscheck
        
        // Die Formel für Smooth Coloring:
        // mu = n + 1 - log(log(|Z|)) / log(2)
        let log2 = log(2.0)
        let mu = Double(iteration) + 1.0 - log(log(magSq) / 2.0) / log2
        
        return mu
    }
}

func calculateDeltaC(pixelC: MPFloat, refC: MPFloat) -> Double {
    let diff = pixelC.copy()
    diff -= refC // Hochpräzise Subtraktion
    return diff.toDouble()
}

/*
 3. Tipps für den "Deep Zoom" Look
 Wenn du extrem tief mit MPFR zoomst, wird die frequency (im Beispiel 0.1) oft zu schnell oder zu langsam wirken.

 Für mehr Kontrast: Erhöhe die Frequenz (z. B. 0.3), dann folgen die Farbgürtel enger aufeinander.

 Für weichere Verläufe: Verringere die Frequenz (z. B. 0.05).

 Psychedelischer Look: Multipliziere den smoothValue innerhalb des Sinus mit einem weiteren Faktor (z. B. log(smoothValue)).
 */
func getColor(smoothValue: Double, maxIter: Int) -> (r: Double, g: Double, b: Double) {
    // Wenn der Punkt nicht entkommen ist, färben wir ihn Schwarz
    if smoothValue >= Double(maxIter) {
        return (0, 0, 0)
    }
    
    // Die Frequenz bestimmt, wieq schnell sich die Farben wiederholen
    let frequency = 0.1
    // Ein Versatz (Offset) sorgt dafür, dass die Kanäle nicht identisch sind
    let r = 0.5 + 0.5 * sin(frequency * smoothValue + 0.0)
    let g = 0.5 + 0.5 * sin(frequency * smoothValue + 2.0)
    let b = 0.5 + 0.5 * sin(frequency * smoothValue + 4.0)
    
    return (r, g, b)
}


import Foundation

func renderFractal(width: Int, height: Int) {
    // Ein Puffer für unsere Pixeldaten (RGBA)
    var pixelData = [UInt8](repeating: 0, count: width * height * 4)
    
    // Wir parallelisieren über die Zeilen (Y-Achse)
    DispatchQueue.concurrentPerform(iterations: height) { y in
        // Jede Iteration hier läuft potenziell auf einem eigenen Thread!
        
        // WICHTIG: Erstelle pro Thread eine eigene Instanz von ComplexMPFloat,
        // da MPFR-Variablen nicht thread-sicher sind, wenn sie geteilt werden.
        let z = ComplexMPFloat(precision: 256)
        let cRe = MPFloat(precision: 256)
        let cIm = MPFloat(precision: 256)
        
        for x in 0..<width {
            // 1. Berechne cRe und cIm für diesen Pixel (x, y)
            // 2. Führe die Mandelbrot-Iteration durch
            // 3. Berechne smoothValue und Farbe
            
            let color = getColor(smoothValue: 123.45, maxIter: 1000) // Beispiel
            
            // Pixel in den Puffer schreiben
            let index = (y * width + x) * 4
            pixelData[index]     = UInt8(color.r * 255) // R
            pixelData[index + 1] = UInt8(color.g * 255) // G
            pixelData[index + 2] = UInt8(color.b * 255) // B
            pixelData[index + 3] = 255                  // A (Alpha)
        }
    }
    
    print("Berechnung abgeschlossen!")
}

import Foundation
import CoreGraphics
import ImageIO

func saveImageData(_ data: [UInt8], width: Int, height: Int, fileName: String) {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
    
    // 1. Daten in einen CGContext laden
    guard let context = CGContext(
        data: UnsafeMutableRawPointer(mutating: data),
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: colorSpace,
        bitmapInfo: bitmapInfo.rawValue
    ) else {
        print("Fehler: Context konnte nicht erstellt werden.")
        return
    }
    
    // 2. CGImage aus dem Context erstellen
    guard let cgImage = context.makeImage() else {
        print("Fehler: Image konnte nicht erstellt werden.")
        return
    }
    
    // 3. Pfad zum Schreibtisch definieren
    let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
    let fileURL = desktopURL.appendingPathComponent("\(fileName).png")
    
    // 4. Als PNG speichern
    guard let destination = CGImageDestinationCreateWithURL(fileURL as CFURL, kUTTypePNG, 1, nil) else {
        print("Fehler: Zielpfad ungültig.")
        return
    }
    
    CGImageDestinationAddImage(destination, cgImage, nil)
    
    if CGImageDestinationFinalize(destination) {
        print("✅ Bild erfolgreich gespeichert: \(fileURL.path)")
    } else {
        print("❌ Speichern fehlgeschlagen.")
    }
}

// Pixel mapping
// Beispiel für die Berechnung pro Pixel
/*
 Ein kleiner Performance-Hack:
 Da MPFloat * Double intern aufwendig ist, berechne das offsetX am besten so:

 Wandle percentX in einen MPFloat um.

 Nutze mpfr_mul.
 */
let aspectRatio = Double(width) / Double(height)
let zoomMP = MPFloat("0.000000000000000000000000000000000000001", precision: 256)

// In der Schleife für jeden Pixel (x, y):
let percentX = (Double(x) / Double(width) - 0.5) * aspectRatio
let percentY = (Double(y) / Double(height) - 0.5)

// cRe = centerRe + (percentX * zoom)
let offsetX = zoomMP.copy()
offsetX *= percentX // Du müsstest noch einen Operator für MPFloat * Double hinzufügen
let currentCRe = centerRe.copy()
currentCRe += offsetX

// Analog für cIm...




/*
 DEEPZOOM BEISPIEL:
 
 Parameter,Wert
 Realteil (Re),-0.7436438870371587089443101006246311336753671032339282857471
 Imaginärteil (Im),0.1318259042060727863332047833052402422037146522851480119151
 Zoom (Breite),0.000000000000000000000000000000000000001 (1e-39)
 Max Iterationen,"5000 bis 20000 (je tiefer der Zoom, desto mehr Iterationen sind nötig)"
 
 */
let precision: Int32 = 256
let cRe = MPFloat("-0.743643887037158708944", precision: precision)
let cIm = MPFloat("0.131825904206072786333", precision: precision)

let z = ComplexMPFloat(precision: precision)
let maxIter = 1000
var escapedAt = maxIter

for i in 0..<maxIter {
    z.iterateMandelbrot(cRe: cRe, cIm: cIm)
    
    if z.magnitudeSquaredDouble() > 4.0 {
        escapedAt = i
        break
    }
}

var d = (re: 0.0, im: 0.0)
let dC = (re: pixelC.re - refC.re, im: pixelC.im - refC.im) // Diese Differenz muss oft hochpräzise berechnet werden!

for n in 0..<maxIter {
    d = referenceOrbit[n].perturbationStep(delta: d, deltaC: dC)

    // Escape check auf der Abweichung (grob)
    if (referenceOrbit[n].re.toDouble() + d.re).magnitudeSquared > 4.0 {
         // escaped!
    }
}

// MAXITER
maxIter = Int(500 + log10(1.0 / currentZoom) * 200)

func renderZoomSequence() {
    let centerX = MPFloat("-0.7436438870371587089443101006246311336753671032339282857471", precision: 256)
    let centerY = MPFloat("0.1318259042060727863332047833052402422037146522851480119151", precision: 256)
    
    let startZoom = 2.0
    let endZoom = 1e-39
    let totalFrames = 120 // 4 Sekunden bei 30 fps
    
    // Berechne den Zoom-Faktor pro Frame
    // Formel: Zoom_n = startZoom * (endZoom / startZoom)^(n / totalFrames)
    let zoomRatio = pow(endZoom / startZoom, 1.0 / Double(totalFrames))
    
    var currentZoom = startZoom
    
    for frame in 0..<totalFrames {
        print("Rendere Frame \(frame) mit Zoom \(currentZoom)...")
        
        let pixelData = renderFrame(centerRe: centerX, centerIm: centerY, zoom: currentZoom)
        
        saveImageData(pixelData, width: 1920, height: 1080, fileName: String(format: "mandelbrot_%03d", frame))
        
        currentZoom *= zoomRatio
    }
}

// VIDEO
// ffmpeg -framerate 30 -i mandelbrot_%03d.png -c:v libx264 -pix_fmt yuv420p mandelbrot_zoom.mp4

/*
 DISTANZ
 
 4. Warum ist das nützlich?Dünne Linien: Du kannst Pixel schwarz färben, deren Distanz kleiner als eine bestimmte Schwelle ist. Das ergibt die berühmten "Filamente", die dünner als ein Pixel sind.Anti-Aliasing: Du kannst die Helligkeit eines Pixels proportional zur Distanz steuern. Wenn die Distanz $d$ kleiner als die Pixelbreite ist, färbst du den Pixel grau statt schwarz. Das verhindert das "Flackern" von feinen Strukturen beim Zoomen.3D-Effekte: Die Distanz kann als "Höhe" interpretiert werden, um Schatteneffekte (Bump Mapping) auf das Fraktal zu legen.
 */

// ORBIT TRAPS
// Beispiel: Abstand zu einer horizontalen Linie (y = 0)
var minOrbitDist = Double.infinity

for i in 0..<maxIter {
    z.iterateWithDerivative(cRe: cRe, cIm: cIm)
    
    // Orbit Trap: Wie nah ist der aktuelle Z-Wert an der x-Achse?
    let currentDist = abs(z.im.toDouble())
    minOrbitDist = min(minOrbitDist, currentDist)
    
    if z.magnitudeSquaredDouble() > 10000.0 { // Großer Bailout für DE wichtig!
        let distance = z.estimateDistance()
        return (escaped: true, dist: distance, trap: minOrbitDist)
    }
}

/*
 FILAMENTE
 2. Nutzung der Distanz für FilamenteUm die hauchdünnen Strukturen (Filamente) darzustellen, die das Mandelbrot-Set wie ein Spinnennetz umgeben, nutzen wir die geschätzte Distanz $d$, um die Linienstärke unabhängig vom Zoom-Level konstant zu halten.Ein Pixel wird als Teil eines Filaments eingefärbt, wenn seine Distanz zum Set kleiner ist als ein Bruchteil der Pixelgröße.
 */
func getFilamentColor(distance: Double, pixelSize: Double, trapDist: Double) -> (Double, Double, Double) {
    // 1. Die "Dicke" der Linie im Verhältnis zur Pixelgröße
    // distance < pixelSize bedeutet: Der Rand läuft durch diesen Pixel
    let edgeWidth = distance / pixelSize
    
    if edgeWidth < 1.0 {
        // Wir sind sehr nah am Set -> Zeichne ein scharfes schwarzes Filament
        // Nutze (1.0 - edgeWidth) für einfaches Anti-Aliasing
        let intensity = edgeWidth // 0.0 = Schwarz (mitten drauf), 1.0 = Hintergrund
        return (intensity, intensity, intensity)
    } else {
        // Hintergrundfarbe basierend auf der Orbit Trap (Muster)
        let r = 0.5 + 0.5 * sin(trapDist * 10.0)
        let g = 0.5 + 0.5 * sin(trapDist * 10.0 + 2.0)
        let b = 0.8
        return (r, g, b)
    }
}

public func iterateWithDerivative(cRe: MPFloat, cIm: MPFloat) {
    // Formel für Z': der = 2 * z * der + 1
    // derRe_new = 2 * (re * derRe - im * derIm) + 1
    // derIm_new = 2 * (re * derIm + im * derRe)
    
    // Nutze tmp1 und tmp2 für die Ableitung
    mpfr_mul(&tmp1.value, &re.value, &derRe.value, MPFR_RNDN)    // re * derRe
    mpfr_mul(&tmp2.value, &im.value, &derIm.value, MPFR_RNDN)    // im * derIm
    mpfr_sub(&tmp1.value, &tmp1.value, &tmp2.value, MPFR_RNDN)   // re*derRe - im*derIm
    
    mpfr_mul(&tmp2.value, &re.value, &derIm.value, MPFR_RNDN)    // re * derIm
    mpfr_mul(&derIm.value, &im.value, &derRe.value, MPFR_RNDN)   // im * derRe
    mpfr_add(&derIm.value, &derIm.value, &tmp2.value, MPFR_RNDN) // re*derIm + im*derRe
    mpfr_mul_ui(&derIm.value, &derIm.value, 2, MPFR_RNDN)        // * 2
    
    mpfr_mul_ui(&derRe.value, &tmp1.value, 2, MPFR_RNDN)         // * 2
    mpfr_add_ui(&derRe.value, &derRe.value, 1, MPFR_RNDN)        // + 1
    
    // Danach die normale Z = Z^2 + c Iteration
    self.iterateMandelbrot(cRe: cRe, cIm: cIm)
}

/*
 HISTOGRAMM COLORING
 
 Wenn du sehr tief in das Mandelbrot-Set zoomst, wirst du oft feststellen, dass die Verteilung der Iterationszahlen extrem ungleichmäßig ist. In manchen Regionen liegen fast alle Punkte bei 10.000 Iterationen, in anderen bei 100. Das führt dazu, dass dein linearer Farbverlauf entweder in den hellen Bereichen "auswäscht" oder die dunklen Details komplett verschluckt.

 Die Histogramm-Entzerrung (Histogram Equalization) löst dieses Problem, indem sie die Farben so verteilt, dass jede Farbe im Bild gleich oft vorkommt.

 1. Schritt: Daten sammeln
 Anstatt das Bild sofort zu zeichnen, speichern wir im ersten Durchgang nur die smoothValue-Ergebnisse aller Pixel in einem Array und zählen in einem Histogramm, wie oft welcher ganzzahlige Iterationswert vorkommt.
 */
var histogram = [Int](repeating: 0, count: maxIter + 1)
var pixelValues = [Double](repeating: 0, count: width * height)
var totalEscapedPixels = 0

// Im Render-Loop:
for y in 0..<height {
    for x in 0..<width {
        let val = calculateSmoothValue(x, y)
        pixelValues[y * width + x] = val
        
        if val < Double(maxIter) {
            histogram[Int(val)] += 1
            totalEscapedPixels += 1
        }
    }
}

/*
 2. Schritt: Kumulatives Histogramm berechnen
 Wir berechnen nun, wie viele Pixel bis zu einer bestimmten Iteration entkommen sind. Das dient uns als Mapping-Tabelle für die Farbe.
 */
var cumulativeSteps = [Double](repeating: 0, count: maxIter + 1)
var sum = 0.0
for i in 0..<maxIter {
    sum += Double(histogram[i])
    cumulativeSteps[i] = sum / Double(totalEscapedPixels)
}

/*
 3. Schritt: Die Farbe zuweisen
 Jetzt nutzen wir den Wert in cumulativeSteps als Index für unseren Farbverlauf. Ein Pixel mit einem smoothValue von 150.5 wird nun nicht mehr starr linear gefärbt, sondern basierend auf seinem Rang im gesamten Bild:
 */
func getEqualizedColor(val: Double) -> Double {
    let i = Int(val)
    let fractional = val - Double(i)
    
    // Lineare Interpolation zwischen den Rängen im Histogramm
    let h0 = cumulativeSteps[i]
    let h1 = cumulativeSteps[i + 1]
    return h0 + (h1 - h0) * fractional
}

// In der finalen Farbschleife:
let colorIndex = getEqualizedColor(val: pixelValues[index])
let color = getColor(smoothValue: colorIndex * 100.0) // 100.0 steuert die Wiederholung

/*
 Kombination mit der Distanzschätzung (Filamente)
 Wenn du das Histogramm mit der Distance Estimation (DE) kombinierst, erhältst du den ultimativen "High-End"-Look. Hier ist ein Beispiel, wie du die Distanz nutzt, um die Filamente über den Hintergrund zu legen:
 */
let de = estimateDistance(x, y)
let hue = getEqualizedColor(val: smoothValue)
var baseColor = colorFromHue(hue) // Dein Sinus-Farbverlauf

// Filament-Überlagerung (Schatteneffekt)
let pixelSize = currentZoom / Double(width)
let filamentStrength = clamp(de / (pixelSize * 0.5), 0.0, 1.0)

// Die Farbe wird zum Filament hin dunkler (schwarze Linien)
baseColor.r *= filamentStrength
baseColor.g *= filamentStrength
baseColor.b *= filamentStrength

/*
 Automatisch Präzision anpassen
 */

enum PrecisionLevel {
    case hardware  // Double (64-bit)
    case high      // MPFR (128-bit)
    case extreme   // MPFR (256-bit+)

    static func forZoom(_ zoom: Double) -> PrecisionLevel {
        if zoom > 1e-13 { return .hardware }
        if zoom > 1e-35 { return .high }
        return .extreme
    }
}

// Hardware Fallback
func renderPixelHardware(cx: Double, cy: Double, maxIter: Int) -> Double {
    var x = 0.0
    var y = 0.0
    var x2 = 0.0
    var y2 = 0.0
    var iter = 0
    
    while x2 + y2 <= 10000.0 && iter < maxIter {
        y = 2 * x * y + cy
        x = x2 - y2 + cx
        x2 = x * x
        y2 = y * y
        iter += 1
    }
    
    // Smooth Coloring für Double
    if iter < maxIter {
        let magSq = x2 + y2
        return Double(iter) + 1.0 - log2(0.5 * log(magSq) / log(10000.0))
    }
    return Double(maxIter)
}
