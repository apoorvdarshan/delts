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
                .frame(height: 52)
                .background(Color.deltsGold, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(Color.deltsInk, lineWidth: 1.6)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(Color.deltsInferno.opacity(0.32), lineWidth: 1)
                        .offset(x: 2, y: 2)
                        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                )
                .shadow(color: Color.deltsInk.opacity(0.1), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .opacity(isLoading ? 0.72 : 1)
    }

    private var label: some View {
        HStack(spacing: 10) {
            if isLoading {
                ProgressView()
                    .tint(Color.deltsInk)
            } else {
                Image(systemName: systemImage)
            }
            Text(title)
                .font(.headline.weight(.black))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .foregroundStyle(Color.deltsInk)
        .padding(.horizontal, 16)
    }
}

struct GlassIconButton: View {
    let title: String
    let systemImage: String
    var tint: Color = .deltsElectricBlue
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 19, weight: .semibold))
                    .frame(width: 34, height: 34)
                    .foregroundStyle(tint)
                    .background(tint.opacity(0.15), in: Circle())
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.deltsInk.opacity(0.56), lineWidth: 1.2)
            )
        }
        .buttonStyle(.plain)
    }
}
