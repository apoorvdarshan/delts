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
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(Color.deltsElectricBlue)
        .disabled(isLoading)
        .opacity(isLoading ? 0.72 : 1)
    }

    private var label: some View {
        HStack(spacing: 10) {
            if isLoading {
                ProgressView()
                    .tint(.white)
            } else {
                Image(systemName: systemImage)
            }
            Text(title)
                .font(.headline.weight(.black))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .foregroundStyle(.white)
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
            .background(Color.deltsCard, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
