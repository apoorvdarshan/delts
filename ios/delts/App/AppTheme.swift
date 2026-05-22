import SwiftUI

extension Color {
    static let deltsBackground = Color(red: 0.012, green: 0.018, blue: 0.026)
    static let deltsCharcoal = Color(red: 0.046, green: 0.055, blue: 0.067)
    static let deltsCard = Color(red: 0.086, green: 0.096, blue: 0.112)
    static let deltsPanel = Color(red: 0.12, green: 0.13, blue: 0.145)
    static let deltsElectricBlue = Color(red: 0.0, green: 0.56, blue: 1.0)
    static let deltsInferno = Color(red: 1.0, green: 0.25, blue: 0.12)
    static let deltsAcidGreen = Color(red: 0.08, green: 0.86, blue: 0.37)
    static let deltsGold = Color(red: 1.0, green: 0.72, blue: 0.1)
    static let deltsMutedText = Color.white.opacity(0.66)
}

struct DeltsBackground: View {
    var body: some View {
        ZStack {
            Color.deltsBackground
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.08, blue: 0.12).opacity(0.95),
                    Color.deltsBackground,
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.deltsElectricBlue.opacity(0.18),
                    Color.clear,
                    Color.deltsInferno.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
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
        tint: Color? = Color.white.opacity(0.12),
        interactive: Bool = false,
        fallbackOpacity: Double = 0.06
    ) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        if #available(iOS 26.0, *) {
            self
                .glassEffect(deltsGlass(tint: tint, interactive: interactive), in: shape)
        } else {
            self
                .background(Color.white.opacity(fallbackOpacity), in: shape)
                .background(.ultraThinMaterial, in: shape)
        }
    }

    @ViewBuilder
    func deltsGlassButton(prominent: Bool = false) -> some View {
        if #available(iOS 26.0, *) {
            if prominent {
                self.buttonStyle(.glassProminent)
            } else {
                self.buttonStyle(.glass)
            }
        } else {
            self.buttonStyle(.plain)
        }
    }
}

@available(iOS 26.0, *)
private func deltsGlass(tint: Color?, interactive: Bool) -> Glass {
    var glass = Glass.regular
    if let tint {
        glass = glass.tint(tint)
    }
    if interactive {
        glass = glass.interactive()
    }
    return glass
}

struct DeltsGlassGroup<Content: View>: View {
    var spacing: CGFloat?
    @ViewBuilder var content: Content

    init(spacing: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) {
                content
            }
        } else {
            content
        }
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
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.deltsMutedText)
                        .textCase(.uppercase)
                }

                Text(title)
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.74)

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
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(Color.white.opacity(0.045), in: Circle())
                    .deltsGlassSurface(cornerRadius: 21, tint: Color.white.opacity(0.14), interactive: true)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
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
                .foregroundStyle(.white)
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
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color.deltsMutedText)
                .lineLimit(1)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
        .background(Color.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .deltsGlassSurface(cornerRadius: 18, tint: tint.opacity(0.12))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
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
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(13)
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
        .background(Color.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
        .deltsGlassSurface(cornerRadius: 17, tint: tint.opacity(0.12), interactive: true)
        .overlay(
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
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
                .stroke(Color.white.opacity(0.11), lineWidth: 8)
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
                    .foregroundStyle(.white)
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
