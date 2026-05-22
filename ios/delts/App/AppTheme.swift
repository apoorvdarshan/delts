import SwiftUI

extension Color {
    static let deltsBackground = Color(uiColor: .systemGroupedBackground)
    static let deltsCharcoal = Color(uiColor: .label)
    static let deltsCard = Color(uiColor: .secondarySystemGroupedBackground)
    static let deltsPanel = Color(uiColor: .tertiarySystemGroupedBackground)
    static let deltsInk = Color(uiColor: .label)
    static let deltsPaper = Color(red: 1.0, green: 0.965, blue: 0.875)
    static let deltsPaperAlt = Color(red: 0.93, green: 0.98, blue: 1.0)
    static let deltsElectricBlue = Color(red: 0.05, green: 0.44, blue: 0.92)
    static let deltsInferno = Color(red: 1.0, green: 0.48, blue: 0.18)
    static let deltsAcidGreen = Color(red: 0.26, green: 0.70, blue: 0.24)
    static let deltsGold = Color(red: 1.0, green: 0.77, blue: 0.14)
    static let deltsPink = Color(red: 1.0, green: 0.43, blue: 0.62)
    static let deltsPurple = Color(red: 0.55, green: 0.34, blue: 0.82)
    static let deltsMutedText = Color(uiColor: .secondaryLabel)
}

struct DeltsBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Color(uiColor: colorScheme == .dark ? .systemBackground : .systemGroupedBackground)
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    backgroundWash.opacity(colorScheme == .dark ? 0.34 : 0.78),
                    Color.clear,
                    Color.deltsInferno.opacity(colorScheme == .dark ? 0.08 : 0.10)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            DoodleBackgroundMarks()
                .opacity(colorScheme == .dark ? 0.42 : 0.62)
        }
    }

    private var backgroundWash: Color {
        colorScheme == .dark ? Color.deltsElectricBlue.opacity(0.16) : Color.deltsPaper
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
        tint: Color? = Color.deltsPanel,
        interactive: Bool = false,
        fallbackOpacity: Double = 0.06
    ) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        self
            .background((tint ?? Color.deltsPanel).opacity(0.16), in: shape)
            .overlay(shape.stroke(Color.deltsInk.opacity(0.68), lineWidth: 1.4))
            .overlay(
                shape
                    .stroke((tint ?? Color.deltsGold).opacity(interactive ? 0.42 : 0.22), lineWidth: 1)
                    .offset(x: 1.5, y: 1.5)
                    .clipShape(shape)
            )
    }

    @ViewBuilder
    func deltsGlassButton(prominent: Bool = false) -> some View {
        self.buttonStyle(.plain)
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
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.deltsMutedText)
                        .textCase(.uppercase)
                }

                HStack(spacing: 6) {
                    Text(title)
                        .font(.largeTitle.weight(.black))
                        .fontDesign(.rounded)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.74)

                    DoodleSparkle(tint: .deltsGold)
                        .frame(width: 18, height: 18)
                        .offset(y: -4)
                }

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
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color.deltsInk)
                    .frame(width: 42, height: 42)
                    .background(Color.deltsGold.opacity(0.22), in: Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.deltsInk.opacity(0.72), lineWidth: 1.4)
                    )
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
                .font(.headline.weight(.black))
                .foregroundStyle(.primary)
            Spacer()
            if let detail {
                Text(detail)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.deltsMutedText)
            }
        }
    }
}

struct DeltsMetricTile: View {
    let title: String
    let value: String
    var systemImage: String
    var tint: Color = .deltsElectricBlue

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(tint)

            Text(value)
                .font(.title3.weight(.black))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color.deltsMutedText)
                .lineLimit(1)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .deltsGlassSurface(cornerRadius: 18, tint: tint.opacity(0.16))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.deltsInk.opacity(0.54), lineWidth: 1)
        )
    }
}

struct DeltsActionTile: View {
    let title: String
    let systemImage: String
    var tint: Color = .deltsElectricBlue

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(tint)
                .frame(width: 38, height: 38)
                .background(tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .deltsGlassSurface(cornerRadius: 12, tint: tint.opacity(0.16), interactive: true)

            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(13)
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
        .deltsGlassSurface(cornerRadius: 17, tint: tint.opacity(0.12), interactive: true)
        .overlay(
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(Color.deltsInk.opacity(0.5), lineWidth: 1)
        )
    }
}

struct DeltsProgressRing: View {
    let progress: Double
    var label: String
    var tint: Color = .deltsElectricBlue

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.deltsInk.opacity(0.14), lineWidth: 8)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(
                    AngularGradient(colors: [tint, .white, tint], center: .center),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 1) {
                Text("\(Int(progress * 100))%")
                    .font(.headline.weight(.black))
                    .foregroundStyle(.primary)
                Text(label)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Color.deltsMutedText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(width: 68, height: 68)
    }
}

struct DoodleSparkle: View {
    var tint: Color = .deltsGold

    var body: some View {
        Canvas { context, size in
            var path = Path()
            path.move(to: CGPoint(x: size.width * 0.5, y: 0))
            path.addLine(to: CGPoint(x: size.width * 0.62, y: size.height * 0.38))
            path.addLine(to: CGPoint(x: size.width, y: size.height * 0.5))
            path.addLine(to: CGPoint(x: size.width * 0.62, y: size.height * 0.62))
            path.addLine(to: CGPoint(x: size.width * 0.5, y: size.height))
            path.addLine(to: CGPoint(x: size.width * 0.38, y: size.height * 0.62))
            path.addLine(to: CGPoint(x: 0, y: size.height * 0.5))
            path.addLine(to: CGPoint(x: size.width * 0.38, y: size.height * 0.38))
            path.closeSubpath()

            context.fill(path, with: .color(tint.opacity(0.75)))
            context.stroke(path, with: .color(.deltsInk.opacity(0.7)), lineWidth: 1.3)
        }
    }
}

struct DoodleCoachIllustration: View {
    var tint: Color = .deltsElectricBlue

    var body: some View {
        ZStack {
            Circle()
                .fill(tint.opacity(0.16))
                .frame(width: 118, height: 118)
                .overlay(Circle().stroke(Color.deltsInk.opacity(0.7), lineWidth: 1.6))

            VStack(spacing: 0) {
                Circle()
                    .fill(Color(red: 0.96, green: 0.74, blue: 0.54))
                    .frame(width: 42, height: 42)
                    .overlay(Circle().stroke(Color.deltsInk, lineWidth: 1.6))
                    .overlay(
                        HStack(spacing: 10) {
                            Circle().fill(Color.deltsInk).frame(width: 3, height: 3)
                            Circle().fill(Color.deltsInk).frame(width: 3, height: 3)
                        }
                        .offset(y: 2)
                    )

                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(tint.opacity(0.75))
                    .frame(width: 58, height: 52)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.deltsInk, lineWidth: 1.6)
                    )
            }
            .offset(y: 8)

            arm(rotation: -28)
                .offset(x: -42, y: 18)
            arm(rotation: 28)
                .offset(x: 42, y: 18)

            DoodleSparkle(tint: .deltsGold)
                .frame(width: 18, height: 18)
                .offset(x: 44, y: -48)
        }
        .accessibilityHidden(true)
    }

    private func arm(rotation: Double) -> some View {
        RoundedRectangle(cornerRadius: 9, style: .continuous)
            .fill(Color(red: 0.96, green: 0.74, blue: 0.54))
            .frame(width: 16, height: 58)
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(Color.deltsInk, lineWidth: 1.4)
            )
            .rotationEffect(.degrees(rotation))
    }
}

private struct DoodleBackgroundMarks: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                mark("sparkle", color: .deltsGold)
                    .frame(width: 18, height: 18)
                    .position(x: proxy.size.width * 0.12, y: 92)
                mark("bolt.fill", color: .deltsInferno)
                    .frame(width: 16, height: 16)
                    .position(x: proxy.size.width * 0.84, y: 146)
                mark("circle", color: .deltsElectricBlue)
                    .frame(width: 13, height: 13)
                    .position(x: proxy.size.width * 0.18, y: proxy.size.height * 0.70)
                mark("leaf.fill", color: .deltsAcidGreen)
                    .frame(width: 15, height: 15)
                    .position(x: proxy.size.width * 0.86, y: proxy.size.height * 0.62)
            }
            .ignoresSafeArea()
        }
    }

    private func mark(_ systemImage: String, color: Color) -> some View {
        Image(systemName: systemImage)
            .font(.caption.weight(.black))
            .foregroundStyle(color.opacity(0.38))
    }
}
