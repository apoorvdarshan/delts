import SwiftUI

extension Color {
    static let deltsBackground = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.118, green: 0.112, blue: 0.098, alpha: 1)
            : UIColor(red: 0.946, green: 0.932, blue: 0.900, alpha: 1)
    })
    static let deltsCharcoal = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.876, green: 0.842, blue: 0.778, alpha: 1)
            : UIColor(red: 0.150, green: 0.138, blue: 0.116, alpha: 1)
    })
    static let deltsCard = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.178, green: 0.166, blue: 0.144, alpha: 1)
            : UIColor(red: 0.902, green: 0.880, blue: 0.836, alpha: 1)
    })
    static let deltsPanel = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.238, green: 0.220, blue: 0.188, alpha: 1)
            : UIColor(red: 0.850, green: 0.818, blue: 0.758, alpha: 1)
    })
    static let deltsHairline = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.402, green: 0.368, blue: 0.300, alpha: 1)
            : UIColor(red: 0.626, green: 0.574, blue: 0.486, alpha: 1)
    })
    static let deltsAccent = Color(red: 0.66, green: 0.27, blue: 0.15)
    static let deltsSecondaryAccent = Color(red: 0.43, green: 0.51, blue: 0.37)
    static let deltsWarning = Color(red: 0.68, green: 0.52, blue: 0.28)
    static let deltsInferno = Color(red: 0.72, green: 0.31, blue: 0.20)
    static let deltsAcidGreen = Color.deltsSecondaryAccent
    static let deltsGold = Color.deltsWarning
    static let deltsOnAccent = Color(red: 0.965, green: 0.925, blue: 0.850)
    static let deltsMutedText = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.682, green: 0.640, blue: 0.566, alpha: 1)
            : UIColor(red: 0.392, green: 0.354, blue: 0.292, alpha: 1)
    })
}

struct DeltsBackground: View {
    var body: some View {
        ZStack {
            Color.deltsBackground
            LinearGradient(
                colors: [
                    Color.deltsBackground,
                    Color.deltsSecondaryAccent.opacity(0.08),
                    Color.deltsPanel.opacity(0.24),
                    Color.deltsAccent.opacity(0.05),
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

    @ViewBuilder
    func deltsGlassSurface(
        cornerRadius: CGFloat = 22,
        tint: Color? = nil,
        interactive: Bool = false,
        fallbackOpacity: Double = 0
    ) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        let resolvedTint = tint ?? Color.deltsCard
        let resolvedOpacity = fallbackOpacity == 0 ? (interactive ? 0.16 : 0.08) : fallbackOpacity

        self
            .background(resolvedTint.opacity(resolvedOpacity), in: shape)
            .overlay(
                shape.stroke(Color.deltsHairline.opacity(interactive ? 0.68 : 0.42), lineWidth: 0.5)
            )
    }

    @ViewBuilder
    func deltsLiquidBarSurface(cornerRadius: CGFloat = 28) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        if #available(iOS 26.0, *) {
            self
                .glassEffect(.regular.interactive(), in: shape)
        } else {
            self
                .background(Color.deltsPanel.opacity(0.62), in: shape)
                .overlay(shape.stroke(Color.deltsHairline.opacity(0.52), lineWidth: 0.5))
        }
    }

    func deltsGlassButton(prominent: Bool = false) -> some View {
        buttonStyle(.plain)
            .tint(prominent ? Color.deltsAccent : Color.deltsSecondaryAccent)
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
                    .foregroundStyle(Color.deltsCharcoal)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)

                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(Color.deltsMutedText)
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
                .foregroundStyle(Color.deltsCharcoal)
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
                .foregroundStyle(Color.deltsCharcoal)
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
                .foregroundStyle(Color.deltsCharcoal)
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
                    .foregroundStyle(Color.deltsCharcoal)
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
