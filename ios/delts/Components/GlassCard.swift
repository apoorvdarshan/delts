import SwiftUI

struct GlassCard<Content: View>: View {
    var padding: CGFloat
    var cornerRadius: CGFloat
    @ViewBuilder var content: Content

    init(padding: CGFloat = 18, cornerRadius: CGFloat = 22, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.deltsCard)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.deltsGold.opacity(0.05))
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.deltsInk.opacity(0.86),
                                Color.deltsInk.opacity(0.62),
                                Color.deltsElectricBlue.opacity(0.42)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.deltsInferno.opacity(0.22), lineWidth: 1)
                    .offset(x: 2, y: 2)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            )
            .shadow(color: Color.deltsInk.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

struct MetricPill: View {
    let title: String
    let value: String
    var systemImage: String
    var tint: Color = .deltsElectricBlue

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 26, height: 26)
                .background(tint.opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(Color.deltsInk.opacity(0.54), lineWidth: 1.2)
        )
    }
}
