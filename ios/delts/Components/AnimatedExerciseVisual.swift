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
    @State private var frames: [UIImage] = []

    var body: some View {
        ZStack {
            if let image = currentImage {
                Color.deltsPanel.opacity(0.18)

                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .transaction { transaction in
                        transaction.animation = nil
                    }
            } else {
                Color.deltsPanel.opacity(0.18)
            }
        }
        .task(id: urls) {
            frameIndex = 0
            frames = urls.compactMap { UIImage(contentsOfFile: $0.path) }
            guard frames.count > 1, !reduceMotion else { return }

            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 850_000_000)
                guard !Task.isCancelled else { return }
                frameIndex = (frameIndex + 1) % frames.count
            }
        }
    }

    private var currentImage: UIImage? {
        guard !frames.isEmpty else { return nil }
        return frames[min(frameIndex, frames.count - 1)]
    }
}
