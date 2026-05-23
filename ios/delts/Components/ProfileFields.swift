import SwiftUI

struct ProfileTextField: View {
    let title: String
    @Binding var text: String
    var axis: Axis = .horizontal

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            TextField(title, text: $text, axis: axis)
                .textFieldStyle(.plain)
                .foregroundStyle(.primary)
                .padding(12)
                .background(Color.deltsPanel, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            HStack {
                TextField(title, value: $value, format: .number.precision(.fractionLength(1)))
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.plain)
                    .foregroundStyle(.primary)
                Text(suffix)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(Color.deltsPanel, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(suffix.isEmpty ? "\(value)" : "\(value) \(suffix)")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
        }
        .tint(Color.deltsAccent)
        .padding(12)
        .background(Color.deltsPanel, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct MultiSelectChipGrid<Option: Identifiable & Hashable>: View {
    let options: [Option]
    @Binding var selection: Set<Option>
    let title: (Option) -> String
    let icon: (Option) -> String

    private let columns = [
        GridItem(.adaptive(minimum: 155), spacing: 10)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(options) { option in
                let isSelected = selection.contains(option)
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
                        if isSelected {
                            selection.remove(option)
                        } else {
                            selection.insert(option)
                        }
                    }
                } label: {
                    HStack(spacing: 9) {
                        Image(systemName: icon(option))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(isSelected ? Color.white : Color.deltsAccent)
                        Text(title(option))
                            .font(.footnote.weight(.semibold))
                            .lineLimit(2)
                            .minimumScaleFactor(0.82)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .foregroundStyle(isSelected ? .white : .primary)
                    .padding(.vertical, 11)
                    .padding(.horizontal, 12)
                    .background(
                        isSelected ? Color.deltsAccent : Color.clear,
                        in: Capsule()
                    )
                    .overlay(
                        Capsule()
                            .stroke(isSelected ? Color.deltsAccent.opacity(0.8) : Color(uiColor: .separator).opacity(0.28), lineWidth: 0.5)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
