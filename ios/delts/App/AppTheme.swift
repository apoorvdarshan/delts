import SwiftUI

enum AppAppearance: String, CaseIterable, Identifiable, Hashable {
    case system
    case light
    case dark
    case darker

    static let storageKey = "app_appearance"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        case .darker: return "Darker"
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark, .darker:
            return .dark
        }
    }

    static var current: AppAppearance {
        AppAppearance(rawValue: UserDefaults.standard.string(forKey: storageKey) ?? "") ?? .system
    }

    static var usesDarkerPalette: Bool {
        current == .darker
    }
}

extension Color {
    static var deltsBackground: Color {
        Color(uiColor: UIColor { traits in
            if AppAppearance.usesDarkerPalette {
                return UIColor(red: 0.000, green: 0.000, blue: 0.000, alpha: 1)
            }
            return traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.047, green: 0.055, blue: 0.052, alpha: 1)
                : UIColor(red: 0.918, green: 0.953, blue: 0.845, alpha: 1)
        })
    }

    static var deltsCharcoal: Color {
        Color(uiColor: UIColor { traits in
            if AppAppearance.usesDarkerPalette {
                return UIColor(red: 0.940, green: 0.975, blue: 0.910, alpha: 1)
            }
            return traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.890, green: 0.935, blue: 0.865, alpha: 1)
                : UIColor(red: 0.056, green: 0.080, blue: 0.066, alpha: 1)
        })
    }

    static var deltsCard: Color {
        Color(uiColor: UIColor { traits in
            if AppAppearance.usesDarkerPalette {
                return UIColor(red: 0.024, green: 0.026, blue: 0.023, alpha: 1)
            }
            return traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.090, green: 0.108, blue: 0.098, alpha: 1)
                : UIColor(red: 0.846, green: 0.914, blue: 0.752, alpha: 1)
        })
    }

    static var deltsPanel: Color {
        Color(uiColor: UIColor { traits in
            if AppAppearance.usesDarkerPalette {
                return UIColor(red: 0.038, green: 0.043, blue: 0.038, alpha: 1)
            }
            return traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.124, green: 0.150, blue: 0.132, alpha: 1)
                : UIColor(red: 0.768, green: 0.864, blue: 0.640, alpha: 1)
        })
    }

    static var deltsHairline: Color {
        Color(uiColor: UIColor { traits in
            if AppAppearance.usesDarkerPalette {
                return UIColor(red: 0.300, green: 0.405, blue: 0.305, alpha: 1)
            }
            return traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.286, green: 0.366, blue: 0.304, alpha: 1)
                : UIColor(red: 0.368, green: 0.516, blue: 0.282, alpha: 1)
        })
    }
    static var deltsAccent: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.70, green: 0.94, blue: 0.26, alpha: 1)
                : UIColor(red: 0.374, green: 0.565, blue: 0.075, alpha: 1)
        })
    }

    static var deltsSecondaryAccent: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.35, green: 0.78, blue: 0.52, alpha: 1)
                : UIColor(red: 0.192, green: 0.494, blue: 0.280, alpha: 1)
        })
    }

    static var deltsWarning: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.76, green: 0.88, blue: 0.24, alpha: 1)
                : UIColor(red: 0.438, green: 0.568, blue: 0.084, alpha: 1)
        })
    }

    static var deltsInferno: Color { Color.deltsSecondaryAccent }
    static var deltsAcidGreen: Color { Color.deltsSecondaryAccent }
    static var deltsGold: Color { Color.deltsWarning }
    static var deltsOnAccent: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.032, green: 0.048, blue: 0.038, alpha: 1)
                : UIColor(red: 0.972, green: 1.000, blue: 0.900, alpha: 1)
        })
    }
    static var deltsMutedText: Color {
        Color(uiColor: UIColor { traits in
            if AppAppearance.usesDarkerPalette {
                return UIColor(red: 0.690, green: 0.765, blue: 0.675, alpha: 1)
            }
            return traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.620, green: 0.710, blue: 0.622, alpha: 1)
                : UIColor(red: 0.236, green: 0.322, blue: 0.220, alpha: 1)
        })
    }
}

struct DeltsBackground: View {
    var body: some View {
        Color.deltsBackground
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
        cornerRadius: CGFloat = 28,
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
    func deltsLiquidBarSurface(cornerRadius: CGFloat = 32) -> some View {
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

    func deltsPressable() -> some View {
        buttonStyle(DeltsPressableButtonStyle())
    }

    func deltsBottomActionBackground() -> some View {
        background(alignment: .top) {
            LinearGradient(
                colors: [
                    Color.deltsBackground.opacity(0),
                    Color.deltsBackground.opacity(0.96)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 34)
            .offset(y: -34)
        }
        .background(Color.deltsBackground.opacity(0.96))
        .background(.bar)
    }
}

struct DeltsPressableButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed && isEnabled

        configuration.label
            .scaleEffect(isPressed ? 0.975 : 1)
            .opacity(isEnabled ? (isPressed ? 0.90 : 1) : 0.55)
            .animation(.easeOut(duration: 0.14), value: isPressed)
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
