import SwiftUI

struct ProfileTextField: View {
    let title: String
    @Binding var text: String
    var axis: Axis = .horizontal

    var body: some View {
        if axis == .vertical {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                TextField(title, text: $text, axis: axis)
                    .textFieldStyle(.plain)
            }
        } else {
            LabeledContent {
                TextField(title, text: $text, axis: axis)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.plain)
            } label: {
                Text(title)
            }
        }
    }
}

struct ProfileNumberField: View {
    let title: String
    let suffix: String
    @Binding var value: Double

    init(title: String, suffix: String, value: Binding<Double>) {
        self.title = title
        self.suffix = suffix
        self._value = value
    }

    var body: some View {
        LabeledContent {
            HStack(spacing: 4) {
                TextField(title, value: $value, format: .number.precision(.fractionLength(1)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.plain)

                Text(suffix)
                    .foregroundStyle(Color.deltsMutedText)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        } label: {
            Text(title)
        }
    }
}

struct IntStepperField: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    var suffix: String = ""

    var body: some View {
        Stepper(value: $value, in: range) {
            LabeledContent {
                Text(displayValue)
                    .foregroundStyle(Color.deltsMutedText)
            } label: {
                Text(title)
            }
        }
    }

    private var displayValue: String {
        suffix.isEmpty ? "\(value)" : "\(value) \(suffix)"
    }
}

struct MultiSelectChecklist<Option: Identifiable & Hashable>: View {
    let options: [Option]
    @Binding var selection: Set<Option>
    let title: (Option) -> String
    let icon: (Option) -> String

    var body: some View {
        ForEach(options) { option in
            let isSelected = selection.contains(option)

            Button {
                withAnimation(.easeInOut(duration: 0.16)) {
                    if isSelected {
                        selection.remove(option)
                    } else {
                        selection.insert(option)
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    Label {
                        Text(title(option))
                            .foregroundStyle(Color.deltsCharcoal)
                    } icon: {
                        Image(systemName: icon(option))
                            .foregroundStyle(Color.deltsSecondaryAccent)
                    }

                    Spacer(minLength: 12)

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Color.deltsAccent)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityValue(isSelected ? "Selected" : "Not selected")
            .accessibilityHint(isSelected ? "Double tap to remove." : "Double tap to select.")
        }
    }
}
