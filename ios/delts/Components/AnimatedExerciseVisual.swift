import Combine
import ImageIO
import SwiftUI
import UIKit

struct AnimatedExerciseVisual: View {
    let muscleGroup: MuscleGroup
    var assetName: String?
    var exerciseName: String?
    var imagePaths: [String] = []
    var equipment: Equipment?
    var height: CGFloat = 170
    @State private var animate = false

    var body: some View {
        ZStack {
            if let resourceName = GIFAssetResolver.resourceName(
                assetName: assetName,
                exerciseName: exerciseName,
                muscleGroup: muscleGroup
            ) {
                AnimatedGIFView(resourceName: resourceName)
            } else if !resolvedImageURLs.isEmpty {
                ExerciseImageSequenceView(urls: resolvedImageURLs)
            } else {
                fallbackVisual
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private var resolvedImageURLs: [URL] {
        let directURLs = FreeExerciseDBAssetResolver.imageURLs(for: imagePaths)
        if !directURLs.isEmpty {
            return directURLs
        }

        return FreeExerciseDBAssetResolver.imageURLs(forExerciseName: exerciseName)
    }

    private var fallbackVisual: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.deltsElectricBlue.opacity(animate ? 0.45 : 0.18),
                    Color.deltsCard,
                    Color.deltsInferno.opacity(animate ? 0.2 : 0.34)
                ],
                startPoint: animate ? .topLeading : .bottomLeading,
                endPoint: animate ? .bottomTrailing : .topTrailing
            )
            .animation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true), value: animate)

            VStack(spacing: 12) {
                Image(systemName: muscleGroup.icon)
                    .font(.system(size: 40, weight: .bold))
                    .symbolEffect(.pulse, options: .repeating, value: animate)
                Text(muscleGroup.title.uppercased())
                    .font(.headline.weight(.black))
                    .tracking(2)
                if let equipment {
                    Text(equipment.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .foregroundStyle(.white)
        }
        .onAppear { animate = true }
    }
}

private struct ExerciseImageSequenceView: View {
    let urls: [URL]
    @State private var selectedIndex = 0

    private let timer = Timer.publish(every: 1.15, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.white

            if let image = currentImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .transition(.opacity)
                    .id(selectedIndex)
                    .padding(4)
            }
        }
        .onReceive(timer) { _ in
            guard urls.count > 1 else {
                return
            }

            withAnimation(.easeInOut(duration: 0.28)) {
                selectedIndex = (selectedIndex + 1) % urls.count
            }
        }
    }

    private var currentImage: UIImage? {
        guard !urls.isEmpty else {
            return nil
        }

        let safeIndex = min(selectedIndex, urls.count - 1)
        return UIImage(contentsOfFile: urls[safeIndex].path)
    }
}

struct AnimatedGIFView: UIViewRepresentable {
    let resourceName: String

    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.image = animatedImage()
        return imageView
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {
        uiView.image = animatedImage()
    }

    private func animatedImage() -> UIImage? {
        guard
            let url = Bundle.main.url(forResource: resourceName, withExtension: "gif"),
            let data = try? Data(contentsOf: url)
        else {
            return nil
        }

        return UIImage.animatedImage(withGIFData: data)
    }
}

private extension UIImage {
    static func animatedImage(withGIFData data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }

        let frameCount = CGImageSourceGetCount(source)
        var images: [UIImage] = []
        var duration: TimeInterval = 0

        for index in 0..<frameCount {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, index, nil) else {
                continue
            }
            duration += frameDuration(at: index, source: source)
            images.append(UIImage(cgImage: cgImage))
        }

        return UIImage.animatedImage(with: images, duration: duration)
    }

    private static func frameDuration(at index: Int, source: CGImageSource) -> TimeInterval {
        let defaultDuration = 0.1
        guard
            let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any],
            let gifProperties = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any]
        else {
            return defaultDuration
        }

        let unclampedDelay = gifProperties[kCGImagePropertyGIFUnclampedDelayTime] as? TimeInterval
        let delay = gifProperties[kCGImagePropertyGIFDelayTime] as? TimeInterval
        let duration = unclampedDelay ?? delay ?? defaultDuration
        return duration < 0.02 ? defaultDuration : duration
    }
}
