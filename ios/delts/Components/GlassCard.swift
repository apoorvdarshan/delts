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
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                if padding == 0 {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.deltsPanel.opacity(0.16))
                }
            }
            .overlay {
                if padding == 0 {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.deltsHairline.opacity(0.40), lineWidth: 0.5)
                }
            }
            .overlay(alignment: .top) {
                if padding > 0 {
                    separator.opacity(0.46)
                }
            }
            .overlay(alignment: .bottom) {
                if padding > 0 {
                    separator
                }
            }
    }

    private var separator: some View {
        Rectangle()
            .fill(Color.deltsHairline.opacity(0.42))
            .frame(height: 0.5)
            .padding(.horizontal, padding > 8 ? 2 : 0)
    }
}

struct MetricPill: View {
    let title: String
    let value: String
    var systemImage: String
    var tint: Color = .deltsAccent

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
                    .foregroundStyle(Color.deltsMutedText)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.deltsCharcoal)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(.vertical, 6)
    }
}
