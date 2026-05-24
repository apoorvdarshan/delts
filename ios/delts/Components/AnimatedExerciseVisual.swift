import SwiftUI
import UIKit

struct AnimatedExerciseVisual: View {
    let muscleGroup: MuscleGroup
    var assetName: String?
    var exerciseName: String?
    var imagePaths: [String] = []
    var equipment: Equipment?
    var height: CGFloat = 170
    var fillsWidth = true
    @State private var animate = false

    var body: some View {
        let imageURLs = resolvedImageURLs

        ZStack {
            if !imageURLs.isEmpty {
                ExerciseImageView(urls: imageURLs)
            } else {
                fallbackVisual
            }
        }
        .frame(maxWidth: fillsWidth ? .infinity : nil)
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(uiColor: .separator).opacity(0.35), lineWidth: 0.5)
        )
    }

    private var resolvedImageURLs: [URL] {
        let directURLs = FreeExerciseDBAssetResolver.imageURLs(for: imagePaths)
        if !directURLs.isEmpty {
            return directURLs
        }

        let namedURLs = FreeExerciseDBAssetResolver.imageURLs(
            forExerciseName: exerciseName,
            muscleGroup: muscleGroup,
            equipment: equipment
        )
        if !namedURLs.isEmpty {
            return namedURLs
        }

        return FreeExerciseDBAssetResolver.imageURLs(
            forMuscleGroup: muscleGroup,
            equipment: equipment
        )
    }

    private var fallbackVisual: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.deltsPanel,
                    Color.deltsCard,
                    Color.deltsAccent.opacity(animate ? 0.20 : 0.10)
                ],
                startPoint: animate ? .topLeading : .bottomLeading,
                endPoint: animate ? .bottomTrailing : .topTrailing
            )
            .animation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true), value: animate)

            VStack(spacing: 12) {
                Image(systemName: muscleGroup.icon)
                    .font(.system(size: 36, weight: .semibold))
                    .symbolEffect(.pulse, options: .repeating, value: animate)
                Text(muscleGroup.title.uppercased())
                    .font(.caption.weight(.bold))
                    .tracking(1.2)
                if let equipment {
                    Text(equipment.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(.primary)
        }
        .onAppear { animate = true }
    }
}

private struct ExerciseImageView: View {
    let urls: [URL]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var frameIndex = 0

    private var currentURL: URL? {
        guard !urls.isEmpty else { return nil }
        return urls[min(frameIndex, urls.count - 1)]
    }

    var body: some View {
        ZStack {
            Color(uiColor: UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(red: 0.925, green: 0.910, blue: 0.880, alpha: 1)
                    : UIColor(red: 0.985, green: 0.975, blue: 0.945, alpha: 1)
            })

            if let image = currentImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .id(currentURL)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.18), value: frameIndex)
        .task(id: urls) {
            frameIndex = 0
            guard urls.count > 1, !reduceMotion else { return }

            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 700_000_000)
                guard !Task.isCancelled else { return }
                frameIndex = (frameIndex + 1) % urls.count
            }
        }
    }

    private var currentImage: UIImage? {
        guard let currentURL else { return nil }
        return UIImage(contentsOfFile: currentURL.path)
    }
}
