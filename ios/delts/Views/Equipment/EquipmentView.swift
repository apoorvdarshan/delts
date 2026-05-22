import PhotosUI
import SwiftData
import SwiftUI

struct EquipmentView: View {
    var body: some View {
        NavigationStack {
            EquipmentManualSelectionView()
        }
    }
}

struct EquipmentManualSelectionView: View {
    @Query(sort: \UserProfile.updatedAt, order: .reverse) private var profiles: [UserProfile]

    var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    scannerShell

                if let profile = profiles.first {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text("Available equipment")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(.primary)
                                Spacer()
                                Text("\(profile.availableEquipment.count) selected")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.secondary)
                            }
                            EquipmentGrid(selection: equipmentBinding(for: profile))
                        }
                    }
                } else {
                    missingProfile
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 18)
        }
        .deltsScreen()
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        DeltsHeader(
            eyebrow: "Equipment Coach",
            title: "Train Around Your Gym",
            subtitle: "Select what your gym has now. Plans adapt around this list.",
            trailingSystemImage: "camera.viewfinder"
        )
    }

    private var scannerShell: some View {
        GlassCard(padding: 0, cornerRadius: 24) {
            ZStack(alignment: .leading) {
                LinearGradient(
                    colors: [
                        Color.deltsElectricBlue.opacity(0.12),
                        Color.deltsPaperAlt,
                        Color.deltsGold.opacity(0.16)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                HStack {
                    VStack(alignment: .leading, spacing: 14) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Scan Equipment")
                                .font(.title2.weight(.black))
                                .fontDesign(.rounded)
                                .foregroundStyle(.primary)
                            Text("Camera shell is ready for Vision or Gemini Vision later.")
                                .font(.subheadline)
                                .foregroundStyle(Color.deltsMutedText)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        NavigationLink {
                            EquipmentScanComingSoonView()
                        } label: {
                            HStack {
                            Image(systemName: "camera.fill")
                            Text("Open Scanner")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(Color.deltsInk)
                        .padding(14)
                        .background(Color.deltsGold, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .stroke(Color.deltsInk, lineWidth: 1.3)
                        )
                    }
                    .buttonStyle(.plain)
                    }

                    Spacer()

                    Image(systemName: "camera.metering.matrix")
                        .font(.system(size: 58, weight: .black))
                        .foregroundStyle(Color.deltsElectricBlue)
                        .frame(width: 96, height: 96)
                        .background(Color.deltsCard, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.deltsInk.opacity(0.58), lineWidth: 1.2)
                        )
                }
                .padding(18)
            }
            .frame(minHeight: 170)
        }
    }

    private var missingProfile: some View {
        GlassCard {
            Text("Profile is being created. Reopen this tab in a moment.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func equipmentBinding(for profile: UserProfile) -> Binding<Set<Equipment>> {
        Binding {
            profile.availableEquipment
        } set: { newValue in
            profile.availableEquipment = newValue
        }
    }
}

struct EquipmentScanComingSoonView: View {
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var statusText = "Equipment scanning coming soon"
    private let scannerService = EquipmentScannerService()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                GlassCard {
                    VStack(alignment: .leading, spacing: 18) {
                        Image(systemName: "camera.metering.matrix")
                            .font(.system(size: 42, weight: .bold))
                            .foregroundStyle(Color.deltsElectricBlue)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Equipment scanning coming soon")
                                .font(.largeTitle.weight(.black))
                                .fontDesign(.rounded)
                                .foregroundStyle(.primary)
                                .lineLimit(3)
                                .minimumScaleFactor(0.72)
                            Text("The MVP includes the UI shell and service placeholder for a future Vision or Gemini Vision classifier.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            HStack {
                                Image(systemName: "photo.on.rectangle")
                                Text("Choose equipment photo")
                                Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.primary)
                        .padding(14)
                        .background(Color.deltsPanel, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .stroke(Color.deltsInk.opacity(0.52), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)

                    Text(statusText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 18)
        }
        .deltsScreen()
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: selectedPhoto) { _, newValue in
            Task {
                do {
                    let imageData = try await newValue?.loadTransferable(type: Data.self)
                    _ = try await scannerService.scanEquipment(fromImageData: imageData)
                } catch {
                    statusText = "Scanner service placeholder ready. Vision/Gemini Vision can be connected later."
                }
            }
        }
    }
}
