import SwiftUI

struct MuscleGlyphIcon: View {
    let title: String
    var muscles: Set<String> = []
    var size: CGFloat = 22
    var tint: Color = .deltsAccent

    private var kind: MuscleGlyphKind {
        MuscleGlyphKind(title: title, muscles: muscles)
    }

    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size)
            let lineWidth = max(1.7, min(size.width, size.height) * 0.085)
            let stroke = StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
            let thinStroke = StrokeStyle(lineWidth: max(1.2, lineWidth * 0.72), lineCap: .round, lineJoin: .round)
            let color = GraphicsContext.Shading.color(tint)
            let softColor = GraphicsContext.Shading.color(tint.opacity(0.18))

            func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                CGPoint(x: rect.minX + rect.width * x, y: rect.minY + rect.height * y)
            }

            func strokePath(_ build: (inout Path) -> Void, style: StrokeStyle = stroke) {
                var path = Path()
                build(&path)
                context.stroke(path, with: color, style: style)
            }

            func fillEllipse(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) {
                context.fill(
                    Path(ellipseIn: CGRect(x: rect.width * x, y: rect.height * y, width: rect.width * w, height: rect.height * h)),
                    with: softColor
                )
            }

            func strokeEllipse(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, style: StrokeStyle = thinStroke) {
                context.stroke(
                    Path(ellipseIn: CGRect(x: rect.width * x, y: rect.height * y, width: rect.width * w, height: rect.height * h)),
                    with: color,
                    style: style
                )
            }

            func line(_ points: [CGPoint], style: StrokeStyle = stroke) {
                strokePath({ path in
                    guard let first = points.first else { return }
                    path.move(to: first)
                    points.dropFirst().forEach { path.addLine(to: $0) }
                }, style: style)
            }

            switch kind {
            case .abs:
                fillEllipse(0.28, 0.18, 0.44, 0.62)
                strokePath { path in
                    path.move(to: point(0.35, 0.18))
                    path.addCurve(to: point(0.28, 0.78), control1: point(0.22, 0.35), control2: point(0.22, 0.62))
                    path.move(to: point(0.65, 0.18))
                    path.addCurve(to: point(0.72, 0.78), control1: point(0.78, 0.35), control2: point(0.78, 0.62))
                    path.move(to: point(0.50, 0.22))
                    path.addLine(to: point(0.50, 0.78))
                }
                line([point(0.35, 0.38), point(0.65, 0.38)], style: thinStroke)
                line([point(0.33, 0.53), point(0.67, 0.53)], style: thinStroke)
                line([point(0.35, 0.68), point(0.65, 0.68)], style: thinStroke)

            case .abductors:
                strokeEllipse(0.31, 0.22, 0.38, 0.30)
                line([point(0.50, 0.50), point(0.26, 0.80)], style: thinStroke)
                line([point(0.50, 0.50), point(0.74, 0.80)], style: thinStroke)
                line([point(0.25, 0.58), point(0.12, 0.58), point(0.18, 0.50)], style: thinStroke)
                line([point(0.75, 0.58), point(0.88, 0.58), point(0.82, 0.50)], style: thinStroke)

            case .adductors:
                strokeEllipse(0.31, 0.22, 0.38, 0.30)
                line([point(0.32, 0.80), point(0.48, 0.50), point(0.68, 0.80)], style: thinStroke)
                line([point(0.10, 0.62), point(0.27, 0.62), point(0.21, 0.54)], style: thinStroke)
                line([point(0.90, 0.62), point(0.73, 0.62), point(0.79, 0.54)], style: thinStroke)

            case .biceps:
                fillEllipse(0.30, 0.22, 0.36, 0.34)
                strokeEllipse(0.26, 0.26, 0.22, 0.24)
                strokePath { path in
                    path.move(to: point(0.30, 0.42))
                    path.addCurve(to: point(0.66, 0.35), control1: point(0.34, 0.16), control2: point(0.62, 0.18))
                    path.addCurve(to: point(0.74, 0.64), control1: point(0.84, 0.40), control2: point(0.82, 0.60))
                    path.addCurve(to: point(0.38, 0.62), control1: point(0.62, 0.72), control2: point(0.46, 0.72))
                }
                line([point(0.70, 0.62), point(0.82, 0.78)], style: thinStroke)

            case .triceps:
                fillEllipse(0.30, 0.28, 0.34, 0.34)
                line([point(0.18, 0.35), point(0.55, 0.35), point(0.82, 0.55)], style: stroke)
                strokePath({ path in
                    path.move(to: point(0.42, 0.48))
                    path.addCurve(to: point(0.66, 0.55), control1: point(0.48, 0.62), control2: point(0.60, 0.64))
                }, style: thinStroke)
                line([point(0.80, 0.55), point(0.88, 0.70)], style: thinStroke)

            case .forearms:
                line([point(0.18, 0.30), point(0.52, 0.54), point(0.84, 0.50)], style: stroke)
                line([point(0.14, 0.52), point(0.48, 0.72), point(0.80, 0.66)], style: thinStroke)
                strokeEllipse(0.76, 0.40, 0.12, 0.16, style: thinStroke)

            case .calves:
                strokePath { path in
                    path.move(to: point(0.42, 0.16))
                    path.addCurve(to: point(0.34, 0.74), control1: point(0.34, 0.34), control2: point(0.30, 0.56))
                    path.addCurve(to: point(0.56, 0.80), control1: point(0.42, 0.88), control2: point(0.54, 0.84))
                    path.addCurve(to: point(0.68, 0.18), control1: point(0.58, 0.58), control2: point(0.68, 0.40))
                }
                line([point(0.43, 0.80), point(0.75, 0.80)], style: thinStroke)

            case .chest:
                fillEllipse(0.19, 0.28, 0.62, 0.28)
                strokePath { path in
                    path.move(to: point(0.20, 0.42))
                    path.addCurve(to: point(0.47, 0.54), control1: point(0.28, 0.22), control2: point(0.44, 0.28))
                    path.move(to: point(0.80, 0.42))
                    path.addCurve(to: point(0.53, 0.54), control1: point(0.72, 0.22), control2: point(0.56, 0.28))
                    path.move(to: point(0.50, 0.30))
                    path.addLine(to: point(0.50, 0.74))
                }
                line([point(0.22, 0.28), point(0.08, 0.38)], style: thinStroke)
                line([point(0.78, 0.28), point(0.92, 0.38)], style: thinStroke)

            case .glutes:
                fillEllipse(0.25, 0.28, 0.24, 0.34)
                fillEllipse(0.51, 0.28, 0.24, 0.34)
                strokeEllipse(0.24, 0.28, 0.25, 0.34)
                strokeEllipse(0.51, 0.28, 0.25, 0.34)
                line([point(0.50, 0.18), point(0.50, 0.68)], style: thinStroke)
                line([point(0.30, 0.66), point(0.24, 0.84)], style: thinStroke)
                line([point(0.70, 0.66), point(0.76, 0.84)], style: thinStroke)

            case .hamstrings:
                strokePath { path in
                    path.move(to: point(0.36, 0.16))
                    path.addCurve(to: point(0.42, 0.62), control1: point(0.26, 0.34), control2: point(0.28, 0.52))
                    path.addCurve(to: point(0.62, 0.80), control1: point(0.58, 0.68), control2: point(0.62, 0.70))
                }
                line([point(0.63, 0.80), point(0.78, 0.78)], style: thinStroke)

            case .lats:
                fillEllipse(0.20, 0.25, 0.60, 0.46)
                strokePath { path in
                    path.move(to: point(0.50, 0.18))
                    path.addLine(to: point(0.50, 0.80))
                    path.move(to: point(0.48, 0.30))
                    path.addCurve(to: point(0.16, 0.72), control1: point(0.22, 0.34), control2: point(0.18, 0.54))
                    path.move(to: point(0.52, 0.30))
                    path.addCurve(to: point(0.84, 0.72), control1: point(0.78, 0.34), control2: point(0.82, 0.54))
                }

            case .lowerBack:
                line([point(0.50, 0.18), point(0.50, 0.76)], style: stroke)
                strokePath({ path in
                    path.move(to: point(0.28, 0.55))
                    path.addCurve(to: point(0.50, 0.76), control1: point(0.34, 0.72), control2: point(0.44, 0.78))
                    path.addCurve(to: point(0.72, 0.55), control1: point(0.56, 0.78), control2: point(0.66, 0.72))
                }, style: thinStroke)
                line([point(0.30, 0.82), point(0.70, 0.82)], style: thinStroke)

            case .middleBack:
                line([point(0.50, 0.16), point(0.50, 0.84)], style: stroke)
                line([point(0.24, 0.34), point(0.76, 0.34)], style: thinStroke)
                line([point(0.20, 0.50), point(0.80, 0.50)], style: thinStroke)
                line([point(0.28, 0.66), point(0.72, 0.66)], style: thinStroke)

            case .neck:
                strokeEllipse(0.39, 0.10, 0.22, 0.22)
                line([point(0.42, 0.34), point(0.42, 0.64)], style: stroke)
                line([point(0.58, 0.34), point(0.58, 0.64)], style: stroke)
                line([point(0.22, 0.70), point(0.50, 0.60), point(0.78, 0.70)], style: thinStroke)

            case .quadriceps:
                fillEllipse(0.30, 0.16, 0.34, 0.48)
                strokePath { path in
                    path.move(to: point(0.42, 0.15))
                    path.addCurve(to: point(0.34, 0.72), control1: point(0.28, 0.38), control2: point(0.28, 0.58))
                    path.move(to: point(0.58, 0.15))
                    path.addCurve(to: point(0.66, 0.72), control1: point(0.72, 0.38), control2: point(0.72, 0.58))
                    path.move(to: point(0.50, 0.20))
                    path.addLine(to: point(0.50, 0.70))
                }
                strokeEllipse(0.39, 0.69, 0.22, 0.14, style: thinStroke)

            case .shoulders:
                fillEllipse(0.12, 0.25, 0.28, 0.28)
                fillEllipse(0.60, 0.25, 0.28, 0.28)
                strokeEllipse(0.11, 0.25, 0.28, 0.28)
                strokeEllipse(0.61, 0.25, 0.28, 0.28)
                line([point(0.25, 0.46), point(0.50, 0.58), point(0.75, 0.46)], style: thinStroke)

            case .traps:
                strokeEllipse(0.40, 0.10, 0.20, 0.20, style: thinStroke)
                strokePath { path in
                    path.move(to: point(0.42, 0.32))
                    path.addLine(to: point(0.22, 0.76))
                    path.addLine(to: point(0.78, 0.76))
                    path.addLine(to: point(0.58, 0.32))
                }

            case .groupUpper:
                strokePath { path in
                    path.move(to: point(0.22, 0.38))
                    path.addCurve(to: point(0.50, 0.58), control1: point(0.32, 0.28), control2: point(0.42, 0.30))
                    path.addCurve(to: point(0.78, 0.38), control1: point(0.58, 0.30), control2: point(0.68, 0.28))
                    path.move(to: point(0.50, 0.24))
                    path.addLine(to: point(0.50, 0.82))
                }
                line([point(0.18, 0.50), point(0.34, 0.72)], style: thinStroke)
                line([point(0.82, 0.50), point(0.66, 0.72)], style: thinStroke)
            case .groupLower:
                line([point(0.36, 0.18), point(0.44, 0.52), point(0.36, 0.82)])
                line([point(0.64, 0.18), point(0.56, 0.52), point(0.64, 0.82)])
                line([point(0.34, 0.82), point(0.52, 0.82)], style: thinStroke)
                line([point(0.62, 0.82), point(0.80, 0.82)], style: thinStroke)
            case .groupPush:
                line([point(0.18, 0.48), point(0.50, 0.28), point(0.82, 0.48)], style: thinStroke)
                line([point(0.50, 0.80), point(0.50, 0.24), point(0.38, 0.36)], style: stroke)
                line([point(0.50, 0.24), point(0.62, 0.36)], style: stroke)
            case .groupPull:
                strokePath { path in
                    path.move(to: point(0.50, 0.20))
                    path.addLine(to: point(0.50, 0.78))
                    path.move(to: point(0.22, 0.38))
                    path.addCurve(to: point(0.50, 0.60), control1: point(0.28, 0.56), control2: point(0.38, 0.62))
                    path.move(to: point(0.78, 0.38))
                    path.addCurve(to: point(0.50, 0.60), control1: point(0.72, 0.56), control2: point(0.62, 0.62))
                }
            case .groupLegs:
                line([point(0.36, 0.18), point(0.44, 0.52), point(0.36, 0.82)])
                line([point(0.64, 0.18), point(0.56, 0.52), point(0.64, 0.82)])
                line([point(0.34, 0.82), point(0.52, 0.82)], style: thinStroke)
                line([point(0.62, 0.82), point(0.80, 0.82)], style: thinStroke)
            case .groupArms:
                line([point(0.18, 0.45), point(0.40, 0.26), point(0.62, 0.44), point(0.82, 0.30)], style: stroke)
                line([point(0.24, 0.66), point(0.48, 0.48), point(0.76, 0.70)], style: thinStroke)
            case .groupBack:
                strokePath { path in
                    path.move(to: point(0.50, 0.18))
                    path.addLine(to: point(0.50, 0.82))
                    path.move(to: point(0.20, 0.34))
                    path.addCurve(to: point(0.18, 0.74), control1: point(0.12, 0.48), control2: point(0.12, 0.62))
                    path.move(to: point(0.80, 0.34))
                    path.addCurve(to: point(0.82, 0.74), control1: point(0.88, 0.48), control2: point(0.88, 0.62))
                }
            case .generic:
                let columns: [CGFloat] = [0.28, 0.56]
                let rows: [CGFloat] = [0.24, 0.52]
                for x in columns {
                    for y in rows {
                        context.stroke(
                            Path(roundedRect: CGRect(x: rect.width * x, y: rect.height * y, width: rect.width * 0.18, height: rect.height * 0.18), cornerRadius: rect.width * 0.035),
                            with: color,
                            style: thinStroke
                        )
                    }
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

enum MuscleGlyphAsset {
    static func name(title: String, muscles: Set<String>) -> String {
        MuscleGlyphKind(title: title, muscles: muscles).assetName
    }
}

private enum MuscleGlyphKind {
    case abs
    case abductors
    case adductors
    case biceps
    case triceps
    case forearms
    case calves
    case chest
    case glutes
    case hamstrings
    case lats
    case lowerBack
    case middleBack
    case neck
    case quadriceps
    case shoulders
    case traps
    case groupUpper
    case groupLower
    case groupPush
    case groupPull
    case groupLegs
    case groupArms
    case groupBack
    case generic

    var assetName: String {
        switch self {
        case .abs:
            return "muscle_icon_abs"
        case .abductors:
            return "muscle_icon_abductors"
        case .adductors:
            return "muscle_icon_adductors"
        case .biceps:
            return "muscle_icon_biceps"
        case .triceps:
            return "muscle_icon_triceps"
        case .forearms:
            return "muscle_icon_forearms"
        case .calves:
            return "muscle_icon_calves"
        case .chest:
            return "muscle_icon_chest"
        case .glutes:
            return "muscle_icon_glutes"
        case .hamstrings:
            return "muscle_icon_hamstrings"
        case .lats:
            return "muscle_icon_lats"
        case .lowerBack:
            return "muscle_icon_lower_back"
        case .middleBack:
            return "muscle_icon_middle_back"
        case .neck:
            return "muscle_icon_neck"
        case .quadriceps:
            return "muscle_icon_quadriceps"
        case .shoulders:
            return "muscle_icon_shoulders"
        case .traps:
            return "muscle_icon_traps"
        case .groupUpper:
            return "muscle_icon_group_upper"
        case .groupLower:
            return "muscle_icon_group_lower"
        case .groupPush:
            return "muscle_icon_group_push"
        case .groupPull:
            return "muscle_icon_group_pull"
        case .groupLegs:
            return "muscle_icon_group_legs"
        case .groupArms:
            return "muscle_icon_group_arms"
        case .groupBack:
            return "muscle_icon_group_back"
        case .generic:
            return "muscle_icon_generic"
        }
    }

    init(title: String, muscles: Set<String>) {
        let normalizedTitle = title.lowercased()

        if muscles.count == 1, let muscle = muscles.first {
            self = MuscleGlyphKind(muscleName: muscle)
            return
        }

        if normalizedTitle.contains("push") {
            self = .groupPush
        } else if normalizedTitle.contains("pull") {
            self = .groupPull
        } else if normalizedTitle.contains("upper") {
            self = .groupUpper
        } else if normalizedTitle.contains("lower") || normalizedTitle.contains("leg") || normalizedTitle.contains("quad") || normalizedTitle.contains("hamstring") {
            self = .groupLower
        } else if normalizedTitle.contains("core") || normalizedTitle.contains("ab") {
            self = .abs
        } else if normalizedTitle.contains("arm") || normalizedTitle.contains("bicep") || normalizedTitle.contains("tricep") {
            self = .groupArms
        } else if normalizedTitle.contains("back") || normalizedTitle.contains("lat") || normalizedTitle.contains("trap") {
            self = .groupBack
        } else if normalizedTitle.contains("chest") {
            self = .chest
        } else if normalizedTitle.contains("shoulder") {
            self = .shoulders
        } else {
            self = MuscleGlyphKind(muscleName: title)
        }
    }

    private init(muscleName: String) {
        switch muscleName.lowercased() {
        case "abdominals":
            self = .abs
        case "abductors":
            self = .abductors
        case "adductors":
            self = .adductors
        case "biceps":
            self = .biceps
        case "triceps":
            self = .triceps
        case "forearms":
            self = .forearms
        case "calves":
            self = .calves
        case "chest":
            self = .chest
        case "glutes":
            self = .glutes
        case "hamstrings":
            self = .hamstrings
        case "lats":
            self = .lats
        case "lower back":
            self = .lowerBack
        case "middle back":
            self = .middleBack
        case "neck":
            self = .neck
        case "quadriceps":
            self = .quadriceps
        case "shoulders":
            self = .shoulders
        case "traps":
            self = .traps
        default:
            self = .generic
        }
    }
}
