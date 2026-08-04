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
struct LabeledPicker<T: Hashable>: View where T: RawRepresentable, T: CaseIterable, T: Identifiable {
    let label: String
    @Binding var selection: T
    var changeHandler: ((T) -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 10) {
            ControlLabel(label)
            Picker("", selection: $selection) {
                ForEach(Array(T.allCases)) { item in
                    Text(String(describing: item).capitalized).tag(item)
                }
            }
            .onChange(of: selection) { _, _ in
                changeHandler?(selection)
            }
            Spacer()
        }.frame(alignment: .leading)
    }
    
}

//
// Options picker with label
//
struct OptionsPicker<T>: View where T: RawRepresentable, T: CaseIterable, T.RawValue == Int {
    let label: String
    @Binding var options: Options<T>
    var changeHandler: ((Options<T>) -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 10) {
            ControlLabel(label)
            Picker("", selection: $options.rawValue) {
                ForEach(Array(T.allCases), id: \.rawValue) { item in
                    Text(String(describing: item).capitalized).tag(item.rawValue)
                }
            }
            .onChange(of: options.rawValue) { _, _ in
                changeHandler?(options)
            }
            Spacer()
        }.frame(alignment: .leading)
    }
    
    init(options: Binding<Options<T>>, _ label: String = "") {
        self.label = label
        self._options = options
    }
    
    func onValueChanged(_ handler: @escaping (Options<T>) -> Void) -> Self {
        var copy = self
        copy.changeHandler = handler
        return copy
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
struct ColorPalette: View {
    var colorTable: EnumColorTable
    var size: CGSize
    var label: String

    var body: some View {
        HStack {
            Image(size: size) { context in
                let graphics = CanvasGraphics(context: context, size: size)
                if colorTable.ct.count > Int(size.width) {
                    let di = Float(colorTable.ct.count) / Float(size.width)
                    for x in 0..<Int(size.width) {
                        let ci = Int(Float(x) * di)
                        graphics.drawLine(from: IPoint(x: x, y: 0), to: IPoint(x: x, y: Int(size.height)), color: colorTable.ct[ci])
                    }
                }
                else {
                    let dx = Int(Float(size.width) / Float(colorTable.ct.count))
                    var ci = 0
                    for x in stride(from: 0, to: Int(size.width), by: dx) {
                        graphics.drawRectFill(
                            from: IPoint(x: x, y: 0),
                            to: IPoint(x: x+dx, y: Int(size.height)-1),
                            color: colorTable.ct[ci]
                        )
                        ci += 1
                    }
                }
            }
            if label != "" {
                Text(label)
            }
        }
    }

}

