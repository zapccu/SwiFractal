//
//  ViewElements.swift
//  SwiFractal
//
//  Created by Dirk Braner on 10.12.24.
//

import SwiftUI
import ParSetKit


struct ProgressRing: View {
    let progress: Double
    var diameter: CGFloat = 240
    var lineWidth: CGFloat = 16
    var ringColor: Color = .orange
    var trackColor: Color = .orange.opacity(0.2)
    var textColor: Color = .white

    var body: some View {
        ZStack {
            Circle()
                .stroke(trackColor, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(ringColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))          // Start oben statt rechts
                .animation(.linear(duration: 0.1), value: progress)

            Text(progress, format: .percent.precision(.fractionLength(0)))
                .font(.system(size: diameter * 0.18, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(textColor)
                .contentTransition(.numericText())
        }
        .frame(width: diameter, height: diameter)
        .padding(lineWidth / 2)                         // Strich nicht abschneiden
    }
}

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

/// Enum picker with label
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

/// Options picker. Options must be CaseIterable.
/// - Parameters:
///   - options: Binding
///   - width: Width of picker
struct OptionsPicker<T>: View where T: NamedIntEnum {
    @Binding var options: T

    var width: CGFloat
    var alignment: Alignment = .leading

    var body: some View {
        Picker("", selection: $options) {
            ForEach(Array(T.allCases), id: \.self) { item in
                Text(item.name.capitalized).tag(item)
            }
        }
        .labelsHidden()
        .frame(minWidth: width, maxWidth: .infinity, alignment: alignment)
    }
}

/// Input field with text label supporting numeric input datatypes
/// - Parameters:
///   - label: Text label
///   - changeHandler: Closure executed when value has changed
///   - width: Width of input field
struct LabeledInputField : View {
    @State private var numberFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
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

/// Image showing a color table with an optional text label
/// - Parameters:
///   - coloring: Coloring
///   - size: Size of image
///   - label: Text label. Default = "", no label
struct ColoringView: View {
    var coloring: EnumColoring
    var size: CGSize
    var label: String = ""

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
        return "\(value) \(unit)"
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
///   - debounce: Debounce time in milliseconds. Default = 0 (no debouncing)
///   - action: Optional async action to perform when slider value changes or when user stops dragging the slider. Default = nil (no action)
/// - Note: If debounce is 0, the action is triggered immediately when the user stops dragging the slider.
/// If debounce is greater than 0, the action is triggered after the specified debounce time has passed since the last value change.
struct LinearSlider<T: BinaryFloatingPoint>: View where T.Stride: BinaryFloatingPoint {
    
    @Binding var value: T
    @State private var isFirstRun: Bool = true
    @State private var lastValue: T? = nil
    
    var range: ClosedRange<T>
    var step: T = 1.0
    var format: String
    var width: CGFloat
    var debounce: Int = 0
    var action: (() async -> Void)? = nil
    
    private var steppedValue: Binding<T> {
        Binding(
            get: { value },
            set: { newValue in
                let rounded = T((newValue / step).rounded() * step)
                value = T(min(max(rounded, range.lowerBound), range.upperBound))
            }
        )
    }
    
    var body: some View {
        Slider(value: steppedValue, in: range) { editing in
            if debounce == 0 && !editing && value != lastValue {
                lastValue = value
                Task {
                    await action?()
                }
            }
        }
            .frame(width: width)
            .task(id: value) {
                guard debounce > 0 && value != lastValue else { return }
                if isFirstRun  {
                    isFirstRun = false
                    return
                }
                lastValue = value
                try? await Task.sleep(for: .milliseconds(debounce))
                guard !Task.isCancelled else { return }
                await action?()
            }
        Text("\(Double(value), specifier: format)").font(.body)
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


