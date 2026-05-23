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
            .background(Color.deltsCard, in: RoundedRectangle(cornerRadius: min(cornerRadius, 18), style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: min(cornerRadius, 18), style: .continuous)
                    .stroke(Color(uiColor: .separator).opacity(0.35), lineWidth: 0.5)
            )
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
        .background(Color.deltsPanel, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
