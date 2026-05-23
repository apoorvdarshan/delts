import SwiftUI

extension Color {
    static let deltsBackground = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.105, green: 0.100, blue: 0.090, alpha: 1)
            : UIColor(red: 0.965, green: 0.955, blue: 0.935, alpha: 1)
    })
    static let deltsCharcoal = Color(uiColor: .label)
    static let deltsCard = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.160, green: 0.152, blue: 0.135, alpha: 1)
            : UIColor(red: 1.000, green: 0.992, blue: 0.970, alpha: 1)
    })
    static let deltsPanel = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.220, green: 0.205, blue: 0.180, alpha: 1)
            : UIColor(red: 0.925, green: 0.908, blue: 0.875, alpha: 1)
    })
    static let deltsAccent = Color(red: 0.84, green: 0.34, blue: 0.16)
    static let deltsSecondaryAccent = Color(red: 0.48, green: 0.57, blue: 0.36)
    static let deltsWarning = Color(red: 0.78, green: 0.55, blue: 0.20)
    static let deltsInferno = Color(red: 0.86, green: 0.25, blue: 0.16)
    static let deltsAcidGreen = Color.deltsSecondaryAccent
    static let deltsGold = Color.deltsWarning
    static let deltsMutedText = Color(uiColor: .secondaryLabel)
}

struct DeltsBackground: View {
    var body: some View {
        ZStack {
            Color.deltsBackground
            LinearGradient(
                colors: [
                    Color.deltsBackground,
                    Color.deltsPanel.opacity(0.34),
                    Color.deltsBackground
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .ignoresSafeArea()
    }
}

extension View {
    func deltsScreen() -> some View {
        background(DeltsBackground())
            .scrollContentBackground(.hidden)
    }

    func deltsGlassSurface(
        cornerRadius: CGFloat = 22,
        tint: Color? = nil,
        interactive: Bool = false,
        fallbackOpacity: Double = 0
    ) -> some View {
        self
    }

    @ViewBuilder
    func deltsLiquidBarSurface(cornerRadius: CGFloat = 28) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        if #available(iOS 26.0, *) {
            self
                .glassEffect(.regular.interactive(), in: shape)
        } else {
            self
                .background(.ultraThinMaterial, in: shape)
        }
    }

    func deltsGlassButton(prominent: Bool = false) -> some View {
        buttonStyle(.plain)
    }
}

struct DeltsGlassGroup<Content: View>: View {
    var spacing: CGFloat?
    @ViewBuilder var content: Content

    init(spacing: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        content
    }
}

struct DeltsHeader: View {
    let eyebrow: String
    let title: String
    var subtitle: String?
    var trailingSystemImage: String?

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                if !eyebrow.isEmpty {
                    Text(eyebrow)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.deltsMutedText)
                }

                Text(title)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)

                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 10)

            if let trailingSystemImage {
                Image(systemName: trailingSystemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.deltsAccent)
                    .frame(width: 38, height: 38)
                    .background(Color.deltsAccent.opacity(0.12), in: Circle())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct DeltsSectionHeader: View {
    let title: String
    var detail: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
            Spacer()
            if let detail {
                Text(detail)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.deltsMutedText)
            }
        }
    }
}

struct DeltsMetricTile: View {
    let title: String
    let value: String
    var systemImage: String
    var tint: Color = .deltsAccent

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.13), in: Circle())

            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.deltsMutedText)
                .lineLimit(1)
        }
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
    }
}

struct DeltsActionTile: View {
    let title: String
    let systemImage: String
    var tint: Color = .deltsAccent

    var body: some View {
        VStack(alignment: .center, spacing: 9) {
            Image(systemName: systemImage)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 48, height: 48)
                .background(tint.opacity(0.14), in: Circle())

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, minHeight: 82)
    }
}

struct DeltsProgressRing: View {
    let progress: Double
    var label: String
    var tint: Color = .deltsAccent

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(uiColor: .tertiaryLabel).opacity(0.25), lineWidth: 8)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(
                    tint,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 1) {
                Text("\(Int(progress * 100))%")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.primary)
                Text(label)
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(Color.deltsMutedText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(width: 68, height: 68)
    }
}
