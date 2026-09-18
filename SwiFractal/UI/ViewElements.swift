//
//  ViewElements.swift
//  SwiFractal
//
//  Created by Dirk Braner on 10.12.24.
//

import SwiftUI
import ParSetKit

//
// A text label in fron of a control element
//
struct ControlLabel : View {
    var label: String
    var width: Int
    
    var body: some View {
        Text(label).frame(width: CGFloat(width), alignment: .trailing)
    }
    
    init (_ label: String, width: Int = 80) {
        self.label = label
        self.width = width
    }
}

//
// Picker with label
//
struct CasePicker<T: Hashable>: View where T: RawRepresentable, T: CaseIterable, T: Identifiable {
    @Binding var selection: T
    
    var width: CGFloat
    
    var body: some View {
        Picker("", selection: $selection) {
            ForEach(Array(T.allCases)) { item in
                Text(String(describing: item).capitalized).tag(item)
            }
        }.frame(width: width)
    }
    
}

///
/// Options picker. Options must be CaseIterable.
/// - Parameters:
///   - options: Binding
///   - width: Width of picker
struct OptionsPicker<T>: View where T: RawRepresentable, T: CaseIterable, T.RawValue == Int {
    @Binding var options: Options<T>
    
    var width: CGFloat
    var alignment: Alignment = .leading
    
    var body: some View {
        Picker("", selection: $options.rawValue) {
            ForEach(Array(T.allCases), id: \.rawValue) { item in
                Text(String(describing: item).capitalized).tag(item.rawValue)
            }
        }
        .frame(minWidth: width, maxWidth: .infinity, alignment: alignment)
    }
}

//
// Input field with text label supporting numeric input datatypes
//
struct LabeledInputField : View {
    @State private var numberFormatter: NumberFormatter = {
        var numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        return numberFormatter
    }()
    
    let label: String
    @Binding var value: String
    var changeHandler: ((String) -> Void)? = nil
    var width: CGFloat

    var body: some View {
        HStack(spacing: 10) {
            ControlLabel(label)
            //TextField(label, value: $value, formatter: numberFormatter)
            TextField(label, text: $value)
                .frame(width: width)
            Spacer()
        }
    }
    
    init(_ label: String, _ value: Binding<String>, width: Int) {
        self.label = label
        self._value = value
        self.width = CGFloat(width)
    }
    
    func onValueChanged(_ handler: @escaping (String) -> Void) -> Self {
        var copy = self
        copy.changeHandler = handler
        return copy
    }
}

//
// Slider with a text label
//
struct LabeledSlider<T> : View where T.Stride == T, T: BinaryFloatingPoint {
    let label: String
    @Binding var value: T
    var changeHandler: ((T) -> Void)? = nil
    var minValue: T
    var maxValue: T
    var step: T
    var format: String
    var width: CGFloat
    
    var body: some View {
        HStack(spacing: 10) {
            ControlLabel(label)
            Slider(value: $value, in: minValue...maxValue)
                .onChange(of: value) { _, _ in
                    changeHandler?(value)
                }
                .frame(width: width)
            Text("\(Float(value), specifier: self.format)").frame(width: 30, alignment: .leading)
            Spacer()
        }
    }
    
    init(_ label: String, _ value: Binding<T>, range: ClosedRange<T>, step: T, width: Int, format: String = "%.2f") {
        self.label = label
        self._value = value
        self.minValue = range.lowerBound
        self.maxValue = range.upperBound
        self.step = step
        self.width = CGFloat(width)
        self.format = format
    }
    
    func onValueChanged(_ handler: @escaping (T) -> Void) -> Self {
        var copy = self
        copy.changeHandler = handler
        return copy
    }
}

//
// Stepper with a text label
//
struct LabeledStepper<T: Strideable> : View where T.Stride == T {
    let label: String
    @Binding var value: T
    var changeHandler: ((T, T) -> Void)? = nil
    var unit: String = ""
    var range: ClosedRange<T>
    var step: T
    
    var body: some View {
        HStack(spacing: 10) {
            if label != "" { ControlLabel(label) }
            Stepper(formatValue() + unit, value: $value, in: range, step: step)
                .onChange(of: value) { oldValue, newValue in
                    changeHandler?(oldValue, newValue)
                }
            Spacer()
        }
    }
          
    init (_ label: String, _ value: Binding<T>, range: ClosedRange<T>, step: T = 1, unit: String = "") {
        self.label = label
        self._value = value
        self.range = range
        self.step = step
        self.unit = unit
    }
    
    func onValueChanged(_ handler: @escaping (T, T) -> Void) -> Self {
        var copy = self
        copy.changeHandler = handler
        return copy
    }
    
    private func formatValue() -> String {
        if let doubleValue = value as? Double {
            // Formatiert Double auf max. 2 Nachkommastellen, entfernt .0
            return doubleValue.formatted(.number.precision(.fractionLength(0...2)))
        }
        return "\(value)"
    }

}

//
// Image showing a color table with an optional text label
//
struct ColoringView: View {
    var coloring: EnumColoring
    var size: CGSize
    var label: String

    var body: some View {
        HStack {
            Image(size: size) { context in
                context.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .linearGradient(
                        Gradient(colors: coloring.coloringType.gradient),
                        startPoint: .zero,
                        endPoint: CGPoint(x: size.width, y: 0)
                    )
                )
            }
            if label != "" {
                Text(label)
            }
        }
    }

}

/// Linear stepper
/// - Parameters:
///   - value: Bindable value
///   - unit: Unit string. Default = ""
///   - range: Range of stepper
///   - step: Step width. Default = 1
///   - format: C-Style format string. Default = nil
struct LinearStepper<T: Strideable> : View where T.Stride == T {
    @Binding var value: T
    var unit: String = ""
    var range: ClosedRange<T>
    var step: T = 1
    var format: String? = nil
 
    var formattedValue: String {
        if let fmt = format, let arg = value as? CVarArg {
            return String(format: fmt, arg) + unit
        }
        return "\(value)\(unit)"
    }
    
    var body: some View {
        Stepper(formattedValue, value: $value, in: range, step: step)
    }
}

/// Linear slider
/// - Parameters:
///   - value: Binding
///   - range: Stride with slider value range
///   - step: Step width. Default = 1
///   - format: Output format of current slider value
///   - width: Width of slider
struct LinearSlider: View {
    
    @Binding var value: Double
    
    var range: ClosedRange<Double>
    var step: Double = 1.0
    var format: String
    var width: CGFloat
    
    private var steppedValue: Binding<Double> {
        Binding(
            get: { value },
            set: { newValue in
                let rounded = (newValue / step).rounded() * step
                value = min(max(rounded, range.lowerBound), range.upperBound)
            }
        )
    }
    
    var body: some View {
        Slider(value: steppedValue, in: range)
            .frame(width: width)
        Text("\(value, specifier: format)").font(.body)
    }
    
}

/// Non linear slider
/// - Parameters:
///   - value: Binding
///   - strides: Array with strides
///   - format: Output format of current slider value
///   - width: Width of slider
struct NonLinearSlider: View {
    
    @Binding var value: Double
    
    var strides: [StrideThrough<Double>]
    var format: String
    var width: CGFloat
    
    /// Return array with all possible values
    var valueList: [Double] {
        strides.flatMap { Array($0) }
    }
    
    /// Return the total number of steps over all strides
    var maxIndex: Double {
        Double(valueList.count - 1)
    }
    
    private var indexBinding: Binding<Double> {
        Binding(
            get: { Double(valueList.firstIndex(of: value)!) },
            set: { newIndex in value = valueList[Int(newIndex)] }
        )
    }
    
    var body: some View {
        Slider(value: indexBinding, in: 0...maxIndex)
            .frame(width: width)
        Text("\(value, specifier: format)").font(.body)
    }
    
}

struct NonLinearSliderStepper: View {
    @Binding var value: Double
    var range: ClosedRange<Double> = 0.1...50.0
    
    // Total steps: 0.1...1.0 (10 steps: indices 0..9), 2.0...50.0 (49 steps: indices 10..58)
    private let maxIndex: Double = 58
    
    private var indexBinding: Binding<Double> {
        Binding(
            get: { index(for: value) },
            set: { newIndex in value = value(for: newIndex) }
        )
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Slider(value: indexBinding, in: 0...maxIndex, step: 1)
            
            Stepper(value: indexBinding, in: 0...maxIndex, step: 1) {
                Text("Wert: \(value, specifier: value < 1.0 ? "%.1f" : "%.0f")")
                    .font(.body)
            }
        }
    }
    
    // MARK: - Mapping Helpers
    private func value(for index: Double) -> Double {
        let i = Int(round(index))
        if i <= 9 {
            return Double(i + 1) * 0.1
        } else {
            return Double(i - 9) + 1.0
        }
    }
    
    private func index(for val: Double) -> Double {
        if val <= 1.0 {
            let steps = round(val / 0.1) - 1.0
            return max(0, min(9, steps))
        } else {
            let steps = round(val) - 1.0 + 9.0
            return max(10, min(maxIndex, steps))
        }
    }
}
