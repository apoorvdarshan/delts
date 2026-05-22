import SwiftUI

struct ProfileTextField: View {
    let title: String
    @Binding var text: String
    var axis: Axis = .horizontal

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.58))
            TextField(title, text: $text, axis: axis)
                .textFieldStyle(.plain)
                .foregroundStyle(.white)
                .padding(12)
                .background(Color.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .deltsGlassSurface(cornerRadius: 14, tint: Color.white.opacity(0.1), interactive: true)
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
                .foregroundStyle(.white.opacity(0.58))
            HStack {
                TextField(title, value: $value, format: .number.precision(.fractionLength(1)))
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.plain)
                    .foregroundStyle(.white)
                Text(suffix)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(12)
            .background(Color.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .deltsGlassSurface(cornerRadius: 14, tint: Color.white.opacity(0.1), interactive: true)
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
                    .foregroundStyle(.white.opacity(0.58))
                Text(suffix.isEmpty ? "\(value)" : "\(value) \(suffix)")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
        }
        .tint(Color.deltsElectricBlue)
        .padding(12)
        .background(Color.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .deltsGlassSurface(cornerRadius: 14, tint: Color.deltsElectricBlue.opacity(0.12), interactive: true)
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
                            .foregroundStyle(isSelected ? Color.white : Color.deltsElectricBlue)
                        Text(title(option))
                            .font(.footnote.weight(.semibold))
                            .lineLimit(2)
                            .minimumScaleFactor(0.82)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .foregroundStyle(.white)
                    .padding(.vertical, 11)
                    .padding(.horizontal, 12)
                    .background(
                        isSelected ? Color.deltsElectricBlue.opacity(0.18) : Color.white.opacity(0.035),
                        in: RoundedRectangle(cornerRadius: 15, style: .continuous)
                    )
                    .deltsGlassSurface(
                        cornerRadius: 15,
                        tint: isSelected ? Color.deltsElectricBlue.opacity(0.2) : Color.white.opacity(0.1),
                        interactive: true
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .stroke(isSelected ? Color.deltsElectricBlue.opacity(0.9) : Color.white.opacity(0.08), lineWidth: 1)
                    )
                }
                .deltsGlassButton()
            }
        }
    }
}
