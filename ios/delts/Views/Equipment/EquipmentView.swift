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
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Scan Equipment")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.primary)
                        Text("Camera shell is ready for Vision or Gemini Vision later.")
                            .font(.subheadline)
                            .foregroundStyle(Color.deltsMutedText)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    NavigationLink("Open Scanner", destination: EquipmentScanComingSoonView())
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)
                        .tint(Color.deltsElectricBlue)
                }

                Spacer()

                Image(systemName: "camera.metering.matrix")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(Color.deltsElectricBlue)
                    .frame(width: 72, height: 72)
                    .background(Color.deltsElectricBlue.opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .padding(18)
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
                                .font(.largeTitle.weight(.bold))
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
                            .background(Color.deltsPanel, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
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
