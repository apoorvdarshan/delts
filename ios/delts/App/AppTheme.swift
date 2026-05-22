import SwiftUI

extension Color {
    static let deltsBackground = Color(red: 0.025, green: 0.027, blue: 0.032)
    static let deltsCharcoal = Color(red: 0.075, green: 0.08, blue: 0.095)
    static let deltsCard = Color(red: 0.105, green: 0.112, blue: 0.135)
    static let deltsElectricBlue = Color(red: 0.0, green: 0.56, blue: 1.0)
    static let deltsInferno = Color(red: 1.0, green: 0.25, blue: 0.12)
    static let deltsMutedText = Color.white.opacity(0.66)
}

struct DeltsBackground: View {
    var body: some View {
        ZStack {
            Color.deltsBackground
                .ignoresSafeArea()
            LinearGradient(
                colors: [
                    Color.deltsElectricBlue.opacity(0.2),
                    Color.clear,
                    Color.deltsInferno.opacity(0.14)
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
}

