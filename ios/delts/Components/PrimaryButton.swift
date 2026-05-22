import SwiftUI

struct PrimaryButton: View {
    let title: String
    var systemImage: String = "bolt.fill"
    var isLoading: Bool = false
    var action: () -> Void

    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                Button(action: action) {
                    label
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                }
                .deltsGlassButton(prominent: true)
                .tint(Color.deltsElectricBlue)
            } else {
                Button(action: action) {
                    label
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            LinearGradient(
                                colors: [.deltsElectricBlue, .deltsInferno],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: RoundedRectangle(cornerRadius: 15, style: .continuous)
                        )
                        .shadow(color: Color.deltsElectricBlue.opacity(0.28), radius: 18, x: 0, y: 10)
                }
                .buttonStyle(.plain)
            }
        }
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
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.42))
            }
            .padding(14)
            .background(Color.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .deltsGlassSurface(cornerRadius: 16, tint: tint.opacity(0.14), interactive: true)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .deltsGlassButton()
    }
}
