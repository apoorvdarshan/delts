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
                                    .foregroundStyle(.white)
                                Spacer()
                                Text("\(profile.availableEquipment.count) selected")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white.opacity(0.58))
                            }
                            EquipmentGrid(selection: equipmentBinding(for: profile))
                        }
                    }
                } else {
                    missingProfile
                }
            }
            .padding(20)
        }
        .deltsScreen()
        .navigationTitle("Equipment")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Equipment coach")
                .font(.largeTitle.weight(.black))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.72)
            Text("Select what your gym has now. The generator filters plans around this list.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.66))
        }
    }

    private var scannerShell: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Scan equipment")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                        Text("Camera and Vision classification will plug into this shell.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.62))
                    }
                    Spacer()
                    Image(systemName: "camera.viewfinder")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.deltsInferno)
                }

                NavigationLink {
                    EquipmentScanComingSoonView()
                } label: {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Open scanner")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(14)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var missingProfile: some View {
        GlassCard {
            Text("Profile is being created. Reopen this tab in a moment.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
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
                                .foregroundStyle(.white)
                                .lineLimit(3)
                                .minimumScaleFactor(0.72)
                            Text("The MVP includes the UI shell and service placeholder for a future Vision or Gemini Vision classifier.")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.66))
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
                            .foregroundStyle(.white)
                            .padding(14)
                            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                        }

                        Text(statusText)
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.58))
                    }
                }
            }
            .padding(20)
        }
        .deltsScreen()
        .navigationTitle("Scanner")
        .navigationBarTitleDisplayMode(.inline)
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
