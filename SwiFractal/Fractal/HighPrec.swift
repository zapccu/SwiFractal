//
//  HighPrec.swift
//  SwiFractal
//
//  Created by Dirk Braner on 16.02.26.
//

/*
 5. Besonderheit für Sandbox (App Sandbox)
 Wenn du eine macOS App entwickelst, ist standardmäßig die "App Sandbox" aktiviert. Diese verhindert den Zugriff auf Dateien außerhalb des App-Containers (wie die /opt/homebrew Libs).

 Gehe zum Reiter Signing & Capabilities.

 Wenn du die App nur für dich lokal zum Rechnen baust: Entferne die App Sandbox mit dem "X".

 Wenn du die Sandbox behalten willst, musst du die Libraries direkt in dein App-Bundle kopieren (Copy Files Build Phase).
 */

import SwiftMPFR


import CMPFR
import Foundation

class HighPrec {
    var value: mpfr_t
    let precision: Int32

    init(prec: Int32 = 128) {
        self.precision = prec
        self.value = mpfr_t()
        mpfr_init2(&self.value, mpfr_prec_t(prec))
    }

    // --- RICHTUNG: STRING -> HIGHPREC ---
    /// Initialisiert eine Zahl aus einem String.
    /// Base 10 ist Standard, 0 erkennt die Basis automatisch (z.B. 0x für Hex).
    convenience init?(_ string: String, prec: Int32 = 128) {
        self.init(prec: prec)
        // mpfr_set_str gibt 0 zurück, wenn die Konvertierung erfolgreich war
        let result = mpfr_set_str(&self.value, string, 10, MPFR_RNDN)
        if result != 0 {
            return nil // Ungültiger String-Format
        }
    }

    // --- RICHTUNG: HIGHPREC -> STRING ---
    /// Konvertiert den Wert in einen String mit einer bestimmten Anzahl an Stellen.
    /// %Rg steht für den MPFR-Float Typ im Format-String.
    /// Profi-Tipp für die Formatierung
    // Beim toString gibt es zwei wichtige Formate für den mpfr_snprintf:
    // %Rf: Fixpunkt-Notation (z. B. 3.14159...). Gut für die Lesbarkeit.
    // %Re: Wissenschaftliche Notation (z. B. 3.141e+00). Wichtig, wenn die Zahlen extrem klein oder groß werden (typisch bei tiefem Zoom in Fraktale).
    // %Rg: Wählt automatisch das kompaktere von beiden (wie im Beispiel oben genutzt).
    /*
     // Alternative (nur falls die obige Version in speziellen Fällen zickt):
     withUnsafePointer(to: self.value) { ptr in
         mpfr_snprintf(&buffer, capacity, format, ptr)
     }
     */
    
    func toString(digits: Int = 32) -> String {
        // Wir berechnen die Puffergröße: Vorzeichen + Ziffern + Punkt + Exponent + Sicherheitsmarge
        let capacity = digits + 32
        var buffer = [Int8](repeating: 0, count: capacity)
        
        // Format-String erstellen, z.B. "%.32Rg"
        let format = "%.\(digits)Rg"
        
        mpfr_snprintf(&buffer, capacity, format, &self.value)
        
        return String(cString: buffer)
    }
    
    deinit {
        mpfr_clear(&self.value)
    }
}

extension HighPrec {
    func copy() -> HighPrec {
        let newObj = HighPrec(prec: self.precision)
        mpfr_set(&newObj.value, &self.value, MPFR_RNDN)
        return newObj
    }
}

// Needed for iteration of high precision reference points with Double values
extension HighPrec {
    func toDouble() -> Double {
        return mpfr_get_d(&self.value, MPFR_RNDN)
    }
}

extension HighPrec {
    // Addition: a + b
    static func + (lhs: HighPrec, rhs: HighPrec) -> HighPrec {
        let res = HighPrec(prec: lhs.precision)
        mpfr_add(&res.value, &lhs.value, &rhs.value, MPFR_RNDN)
        return res
    }
    
    // Subtraktion: a - b
    static func - (lhs: HighPrec, rhs: HighPrec) -> HighPrec {
        let res = HighPrec(prec: lhs.precision)
        mpfr_sub(&res.value, &lhs.value, &rhs.value, MPFR_RNDN)
        return res
    }
    
    // Multiplikation: a * b
    static func * (lhs: HighPrec, rhs: HighPrec) -> HighPrec {
        let res = HighPrec(prec: lhs.precision)
        mpfr_mul(&res.value, &lhs.value, &rhs.value, MPFR_RNDN)
        return res
    }
    
    // Division: a / b
    static func / (lhs: HighPrec, rhs: HighPrec) -> HighPrec {
        let res = HighPrec(prec: lhs.precision)
        mpfr_div(&res.value, &lhs.value, &rhs.value, MPFR_RNDN)
        return res
    }
}

extension HighPrec {
    // Quadrat-Funktion (Z^2) - deutlich schneller als Z * Z
    func squared() -> HighPrec {
        let res = HighPrec(prec: self.precision)
        mpfr_pow_ui(&res.value, &self.value, 2, MPFR_RNDN)
        return res
    }
    
    // Multiplikation mit einem Integer (z.B. 2 * Z)
    static func * (lhs: Int, rhs: HighPrec) -> HighPrec {
        let res = HighPrec(prec: rhs.precision)
        mpfr_mul_si(&res.value, &rhs.value, lhs, MPFR_RNDN)
        return res
    }
}

extension HighPrec {
    // In-Place Addition: a += b
    static func += (lhs: inout HighPrec, rhs: HighPrec) {
        mpfr_add(&lhs.value, &lhs.value, &rhs.value, MPFR_RNDN)
    }
    
    // In-Place Subtraktion: a -= b
    static func -= (lhs: inout HighPrec, rhs: HighPrec) {
        mpfr_sub(&lhs.value, &lhs.value, &rhs.value, MPFR_RNDN)
    }
    
    // In-Place Multiplikation: a *= b
    static func *= (lhs: inout HighPrec, rhs: HighPrec) {
        mpfr_mul(&lhs.value, &lhs.value, &rhs.value, MPFR_RNDN)
    }
}

extension HighPrec {
    /// Prüft, ob x^2 + y^2 > thresholdSquared (meistens 4.0)
    static func hasEscaped(re: HighPrec, im: HighPrec, thresholdSquared: Int = 4) -> Bool {
        let x2 = HighPrec(prec: re.precision)
        let y2 = HighPrec(prec: im.precision)
        let sum = HighPrec(prec: re.precision)
        
        // x^2
        mpfr_pow_ui(&x2.value, &re.value, 2, MPFR_RNDN)
        // y^2
        mpfr_pow_ui(&y2.value, &im.value, 2, MPFR_RNDN)
        // x^2 + y^2
        mpfr_add(&sum.value, &x2.value, &y2.value, MPFR_RNDN)
        
        // Vergleiche mit thresholdSquared (4)
        // mpfr_cmp_si gibt > 0 zurück, wenn sum > thresholdSquared
        return mpfr_cmp_si(&sum.value, Int(thresholdSquared)) > 0
    }
}

func checkEscapeOptimized(zRe: HighPrec, zIm: HighPrec, tmp1: inout HighPrec, tmp2: inout HighPrec) -> Bool {
    // Wir nutzen die tmp-Variablen, die wir sowieso für die Iteration haben
    mpfr_pow_ui(&tmp1.value, &zRe.value, 2, MPFR_RNDN) // x^2
    mpfr_pow_ui(&tmp2.value, &zIm.value, 2, MPFR_RNDN) // y^2
    
    // Wir addieren tmp2 direkt auf tmp1 für den Vergleich
    mpfr_add(&tmp1.value, &tmp1.value, &tmp2.value, MPFR_RNDN)
    
    return mpfr_cmp_si(&tmp1.value, 4) > 0
}

// Mandelbrot-Iteration
func calculateNextStep(z: HighPrec, c: HighPrec) -> HighPrec {
    // Die mathematische Formel: Z_{n+1} = Z_n^2 + C
    // Ohne komplexe Zahlen-Logik (nur Realteil-Beispiel):
    let nextZ = z.squared() + c
    return nextZ
}

// Berechnung des Referenzpunkts (Z = Z^2 + C)
func generateReferenceOrbit(cRe: String, cIm: String, maxIter: Int) -> [HighPrecComplex] {
    let re = HighPrec(cRe)
    let im = HighPrec(cIm)
    var zRe = HighPrec("0.0")
    var zIm = HighPrec("0.0")
    
    // Unsere Arbeits-Variablen (Recycling!)
    var t1 = HighPrec()
    var t2 = HighPrec()
    
    var orbit: [HighPrecComplex] = []

    for _ in 0..<maxIter {
        // 1. Aktuellen Punkt speichern (muss kopiert werden!)
        orbit.append(HighPrecComplex(re: zRe.copy(), im: zIm.copy()))
        
        // 2. Escape Check
        if checkEscapeOptimized(zRe: zRe, zIm: zIm, tmp1: &t1, tmp2: &t2) {
            break
        }
        
        // 3. Nächster Schritt (In-Place)
        iterateInPlace(zRe: &zRe, zIm: &zIm, cRe: re, cIm: im, tmp1: &t1, tmp2: &t2)
    }
    return orbit
}

iterateReference(cRe: "-0.74364388703715870894431", cIm: "0.13182590420631923349")

// Mandelbrot Inplace Iteration
// In dieser Funktion werden tmp1 und tmp2 als inout-Parameter übergeben. Das ist der "Profi-Trick":
// Du erstellst diese Hilfsvariablen einmalig vor der Schleife und reichst sie nur herum.
// Dadurch findet innerhalb der 10.000 Iterationen deines Referenz-Orbits keine einzige Speicherreservierung statt.
func iterateInPlace(zRe: inout HighPrec, zIm: inout HighPrec, cRe: HighPrec, cIm: HighPrec, tmp1: inout HighPrec, tmp2: inout HighPrec) {
    // Formel:
    // newRe = zRe^2 - zIm^2 + cRe
    // newIm = 2 * zRe * zIm + cIm
    
    // 1. tmp1 = zRe^2
    mpfr_pow_ui(&tmp1.value, &zRe.value, 2, MPFR_RNDN)
    
    // 2. tmp2 = zIm^2
    mpfr_pow_ui(&tmp2.value, &zIm.value, 2, MPFR_RNDN)
    
    // 3. Berechne Imaginärteil: zIm = 2 * zRe * zIm + cIm
    // Wir nutzen mpfr_mul_si für den Faktor 2 (sehr schnell)
    mpfr_mul(&zIm.value, &zRe.value, &zIm.value, MPFR_RNDN)
    mpfr_mul_si(&zIm.value, &zIm.value, 2, MPFR_RNDN)
    zIm += cIm
    
    // 4. Berechne Realteil: zRe = tmp1 - tmp2 + cRe
    mpfr_sub(&zRe.value, &tmp1.value, &tmp2.value, MPFR_RNDN)
    zRe += cRe
}


struct ComplexDouble {
    var re: Double
    var im: Double
}

func calculateDeltaPixel(deltaC: ComplexDouble, referenceOrbit: [HighPrecComplex], maxIter: Int) -> Int {
    var dzRe = deltaC.re
    var dzIm = deltaC.im
    
    for n in 0..<min(referenceOrbit.count - 1, maxIter) {
        // Hol den Referenzpunkt aus dem 128-Bit Speicher und wandle ihn in Double
        let ZnRe = referenceOrbit[n].re.toDouble()
        let ZnIm = referenceOrbit[n].im.toDouble()
        
        // Die Perturbations-Formel:
        // dz_next = 2 * Zn * dz + dz^2 + dc
        
        // 1. (2 * Zn * dz)
        let twoZn_dz_Re = 2 * (ZnRe * dzRe - ZnIm * dzIm)
        let twoZn_dz_Im = 2 * (ZnRe * dzIm + ZnIm * dzRe)
        
        // 2. (dz^2)
        let dz2Re = dzRe * dzRe - dzIm * dzIm
        let dz2Im = 2 * dzRe * dzIm
        
        // 3. Alles zusammenfügen
        dzRe = twoZn_dz_Re + dz2Re + deltaC.re
        dzIm = twoZn_dz_Im + dz2Im + deltaC.im
        
        // 4. Escape Check auf Delta-Basis
        // Achtung: Wir prüfen, ob der absolute Punkt (Z + dz) entkommt!
        let totalZRe = ZnRe + dzRe
        let totalZIm = ZnIm + dzIm
        
        if (totalZRe * totalZRe + totalZIm * totalZIm) > 4.0 {
            return n // Punkt ist entkommen
        }
    }
    
    return maxIter // Punkt ist (wahrscheinlich) in der Menge
}



// --- Anwendung ---

// 1. String -> HighPrec (Sicherer Import ohne Double-Ungenauigkeit)
let piString = "3.1415926535897932384626433832795028841971"
if let highPi = HighPrec(piString, prec: 128) {
    
    // Rechne etwas...
    // mpfr_mul_ui(&highPi.value, &highPi.value, 2, MPFR_RNDN)
    
    // 2. HighPrec -> String (Export für UI oder Logs)
    let output = highPi.toString(digits: 40)
    print("Präziser Wert: \(output)")
}

let centerC = HighPrecisionComplex(
    "-0.74364388703715870894431010062499",
    "0.13182590420631923349282321403635",
    precision: 128
)

let refCalc = PerturbationReference(maxIterations: 1000)
refCalc.calculateOrbit(from: centerC)

print("Referenz-Orbit berechnet. Schritte: \(refCalc.orbit.count)")
if let last = refCalc.orbit.last {
    print("Letzter Punkt: \(last.re)")
}
