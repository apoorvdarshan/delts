import SwiftUI

struct PrimaryButton: View {
    let title: String
    var systemImage: String = "bolt.fill"
    var isLoading: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            label
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(DeltsPrimaryButtonStyle(isLoading: isLoading))
        .disabled(isLoading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(title))
        .accessibilityValue(isLoading ? Text("In progress") : Text(""))
    }

    private var label: some View {
        HStack(spacing: 10) {
            if isLoading {
                ProgressView()
                    .controlSize(.small)
                    .tint(Color.deltsOnAccent)
            } else {
                Image(systemName: systemImage)
                    .font(.headline.weight(.semibold))
            }
            Text(title)
                .font(.headline.weight(.semibold))
                .lineLimit(2)
                .minimumScaleFactor(0.82)
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(Color.deltsOnAccent)
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }
}

private struct DeltsPrimaryButtonStyle: ButtonStyle {
    var isLoading: Bool
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: 17, style: .continuous)
        let pressed = configuration.isPressed && isEnabled && !isLoading

        configuration.label
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(
                LinearGradient(
                    colors: fillColors(isPressed: pressed),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: shape
            )
            .overlay(
                shape.stroke(Color.deltsHairline.opacity(isEnabled ? 0.42 : 0.24), lineWidth: 0.5)
            )
            .shadow(
                color: Color.deltsAccent.opacity(isEnabled && !isLoading ? shadowOpacity : 0),
                radius: 8,
                x: 0,
                y: 4
            )
            .scaleEffect(pressed ? 0.985 : 1)
            .opacity(isEnabled ? 1 : 0.68)
            .animation(.easeOut(duration: 0.16), value: pressed)
    }

    private var shadowOpacity: Double {
        colorScheme == .dark ? 0.16 : 0.11
    }

    private func fillColors(isPressed: Bool) -> [Color] {
        if !isEnabled {
            return [
                Color.deltsAccent.opacity(0.50),
                Color.deltsAccent.opacity(0.40)
            ]
        }

        if isLoading {
            return [
                Color.deltsAccent.opacity(0.72),
                Color.deltsAccent.opacity(0.62)
            ]
        }

        return [
            Color.deltsAccent.opacity(isPressed ? 0.86 : 1),
            Color.deltsInferno.opacity(isPressed ? 0.76 : 0.92)
        ]
    }
}

struct GlassIconButton: View {
    let title: String
    let systemImage: String
    var tint: Color = .deltsAccent
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 19, weight: .semibold))
                    .frame(width: 34, height: 34)
                    .foregroundStyle(tint)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.deltsCharcoal)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.deltsMutedText)
            }
            .padding(14)
            .background(Color.deltsPanel.opacity(0.22), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.deltsHairline.opacity(0.34), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}
