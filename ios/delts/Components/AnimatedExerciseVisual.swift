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
        ZStack {
            if let imageURL = resolvedImageURLs.first {
                ExerciseImageView(url: imageURL)
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
    let url: URL

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
            }
        }
    }

    private var currentImage: UIImage? {
        UIImage(contentsOfFile: url.path)
    }
}
