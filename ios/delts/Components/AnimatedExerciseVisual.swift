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
                        .foregroundStyle(Color.deltsMutedText)
                }
            }
            .foregroundStyle(Color.deltsCharcoal)
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
            if !frames.isEmpty {
                Color.deltsPanel.opacity(0.18)

                ZStack {
                    ForEach(frames.indices, id: \.self) { index in
                        Image(uiImage: frames[index])
                            .resizable()
                            .scaledToFill()
                            .saturation(0.30)
                            .grayscale(0.36)
                            .contrast(1.10)
                            .brightness(-0.05)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                            .opacity(index == frameIndex ? 1 : 0)
                    }
                }
                .animation(.easeInOut(duration: 0.18), value: frameIndex)
            } else {
                Color.deltsPanel.opacity(0.18)
            }
        }
        .task(id: urls) {
            let loadedFrames = ExerciseImageCache.shared.images(for: urls)
            if !loadedFrames.isEmpty {
                frameIndex = 0
                frames = loadedFrames
            }
            guard frames.count > 1, !reduceMotion else { return }

            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_050_000_000)
                guard !Task.isCancelled else { return }
                frameIndex = (frameIndex + 1) % frames.count
            }
        }
    }

}

private final class ExerciseImageCache {
    static let shared = ExerciseImageCache()

    private var imagesByURL: [URL: UIImage] = [:]
    private let lock = NSLock()

    private init() {}

    func images(for urls: [URL]) -> [UIImage] {
        urls.compactMap { image(for: $0) }
    }

    private func image(for url: URL) -> UIImage? {
        lock.lock()
        if let image = imagesByURL[url] {
            lock.unlock()
            return image
        }
        lock.unlock()

        guard let image = UIImage(contentsOfFile: url.path) else {
            return nil
        }

        lock.lock()
        imagesByURL[url] = image
        lock.unlock()
        return image
    }
}
