import SwiftUI

struct PrimaryButton: View {
    let title: String
    var systemImage: String = "bolt.fill"
    var isLoading: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .foregroundStyle(.white)
            .background(
                LinearGradient(
                    colors: [.deltsElectricBlue, .deltsInferno],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .shadow(color: Color.deltsElectricBlue.opacity(0.25), radius: 18, x: 0, y: 10)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .opacity(isLoading ? 0.72 : 1)
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
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.42))
            }
            .padding(14)
            .background(Color.white.opacity(0.065), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

