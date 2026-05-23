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
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var scannerStatusText = "Ready"

    private let scannerService = EquipmentScannerService()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                scannerShell

                if let profile = profiles.first {
                    equipmentSection(for: profile)
                } else {
                    missingProfile
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 18)
        }
        .deltsScreen()
        .navigationTitle("Equipment")
        .navigationBarTitleDisplayMode(.large)
        .contentMargins(.bottom, 110, for: .scrollContent)
        .onChange(of: selectedPhoto) { _, newValue in
            handlePhotoSelection(newValue)
        }
    }

    private var selectedEquipmentCount: Int {
        profiles.first?.availableEquipment.count ?? 0
    }

    private var scannerShell: some View {
        EquipmentScannerShell(
            title: "Scan Equipment",
            subtitle: "Photo scan or manual check-in",
            selectedCount: selectedEquipmentCount,
            statusText: scannerStatusText
        ) {
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                EquipmentScannerControlLabel(
                    title: "Photo",
                    systemImage: "photo.on.rectangle",
                    isProminent: true
                )
            }
            .buttonStyle(.plain)
        } secondaryControl: {
            Button {
                scannerStatusText = "Manual mode"
            } label: {
                EquipmentScannerControlLabel(
                    title: "Manual",
                    systemImage: "checklist",
                    isProminent: false
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func equipmentSection(for profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Available Equipment")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)

                Spacer()

                Text("\(profile.availableEquipment.count) selected")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            EquipmentGrid(selection: equipmentBinding(for: profile))
        }
    }

    private var missingProfile: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.deltsAccent)
                .frame(width: 34, height: 34)
                .background(Color.deltsAccent.opacity(0.12), in: Circle())

            Text("Profile is being created. Reopen this tab in a moment.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(uiColor: .separator).opacity(0.18), lineWidth: 0.5)
        }
    }

    private func equipmentBinding(for profile: UserProfile) -> Binding<Set<Equipment>> {
        Binding {
            profile.availableEquipment
        } set: { newValue in
            profile.availableEquipment = newValue
        }
    }

    private func handlePhotoSelection(_ item: PhotosPickerItem?) {
        guard let item else { return }
        scannerStatusText = "Reading photo"

        Task {
            do {
                let imageData = try await item.loadTransferable(type: Data.self)
                _ = try await scannerService.scanEquipment(fromImageData: imageData)
                await MainActor.run {
                    scannerStatusText = "Scan complete"
                }
            } catch {
                await MainActor.run {
                    scannerStatusText = "Photo selected"
                }
            }
        }
    }
}

struct EquipmentScanComingSoonView: View {
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var statusText = "Ready"

    private let scannerService = EquipmentScannerService()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                scannerShell
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 18)
        }
        .deltsScreen()
        .navigationTitle("Scan Equipment")
        .navigationBarTitleDisplayMode(.inline)
        .contentMargins(.bottom, 110, for: .scrollContent)
        .onChange(of: selectedPhoto) { _, newValue in
            handlePhotoSelection(newValue)
        }
    }

    private var scannerShell: some View {
        EquipmentScannerShell(
            title: "Equipment Scanner",
            subtitle: "Photo scan or manual check-in",
            selectedCount: nil,
            statusText: statusText
        ) {
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                EquipmentScannerControlLabel(
                    title: "Photo",
                    systemImage: "photo.on.rectangle",
                    isProminent: true
                )
            }
            .buttonStyle(.plain)
        } secondaryControl: {
            Button {
                statusText = "Manual mode"
            } label: {
                EquipmentScannerControlLabel(
                    title: "Manual",
                    systemImage: "checklist",
                    isProminent: false
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func handlePhotoSelection(_ item: PhotosPickerItem?) {
        guard let item else { return }
        statusText = "Reading photo"

        Task {
            do {
                let imageData = try await item.loadTransferable(type: Data.self)
                _ = try await scannerService.scanEquipment(fromImageData: imageData)
                await MainActor.run {
                    statusText = "Scan complete"
                }
            } catch {
                await MainActor.run {
                    statusText = "Photo selected"
                }
            }
        }
    }
}

private struct EquipmentScannerShell<PrimaryControl: View, SecondaryControl: View>: View {
    let title: String
    let subtitle: String
    let selectedCount: Int?
    let statusText: String

    private let primaryControl: PrimaryControl
    private let secondaryControl: SecondaryControl

    init(
        title: String,
        subtitle: String,
        selectedCount: Int?,
        statusText: String,
        @ViewBuilder primaryControl: () -> PrimaryControl,
        @ViewBuilder secondaryControl: () -> SecondaryControl
    ) {
        self.title = title
        self.subtitle = subtitle
        self.selectedCount = selectedCount
        self.statusText = statusText
        self.primaryControl = primaryControl()
        self.secondaryControl = secondaryControl()
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(scannerBackground)

            EquipmentScannerCornerBrackets()
                .stroke(Color.primary.opacity(0.28), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .padding(4)

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)

                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }

                    Spacer(minLength: 12)

                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Color.deltsAccent)
                        .accessibilityHidden(true)
                }

                EquipmentScannerStatusPill(
                    selectedCount: selectedCount,
                    statusText: statusText
                )

                Spacer(minLength: 16)

                Image(systemName: "viewfinder")
                    .font(.system(size: 54, weight: .thin))
                    .foregroundStyle(Color.primary.opacity(0.16))
                    .frame(maxWidth: .infinity)
                    .accessibilityHidden(true)

                Spacer(minLength: 76)
            }
            .padding(18)

            VStack {
                Spacer()

                HStack(spacing: 10) {
                    primaryControl
                    secondaryControl
                }
                .padding(8)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color(uiColor: .separator).opacity(0.22), lineWidth: 0.5)
                }
                .padding(12)
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1.12, contentMode: .fit)
        .frame(minHeight: 280)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color(uiColor: .separator).opacity(0.18), lineWidth: 0.5)
        }
    }

    private var scannerBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color(uiColor: .secondarySystemGroupedBackground),
                Color(uiColor: .tertiarySystemGroupedBackground),
                Color.deltsAccent.opacity(0.10)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private struct EquipmentScannerStatusPill: View {
    let selectedCount: Int?
    let statusText: String

    var body: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(Color.deltsAccent)
                .frame(width: 7, height: 7)

            Text(label)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.primary)
        .padding(.horizontal, 11)
        .padding(.vertical, 7)
        .background(.regularMaterial, in: Capsule())
        .accessibilityLabel(label)
    }

    private var label: String {
        if let selectedCount {
            return "\(selectedCount) selected - \(statusText)"
        }
        return statusText
    }
}

private struct EquipmentScannerControlLabel: View {
    let title: String
    let systemImage: String
    let isProminent: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))

            Text(title)
                .lineLimit(1)
                .minimumScaleFactor(0.86)
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(isProminent ? Color.white : Color.primary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .background(isProminent ? Color.deltsAccent : Color(uiColor: .tertiarySystemFill), in: Capsule())
        .contentShape(Capsule())
    }
}

private struct EquipmentScannerCornerBrackets: Shape {
    func path(in rect: CGRect) -> Path {
        let inset: CGFloat = 22
        let length = min(rect.width, rect.height) * 0.14
        var path = Path()

        path.move(to: CGPoint(x: rect.minX + inset + length, y: rect.minY + inset))
        path.addLine(to: CGPoint(x: rect.minX + inset, y: rect.minY + inset))
        path.addLine(to: CGPoint(x: rect.minX + inset, y: rect.minY + inset + length))

        path.move(to: CGPoint(x: rect.maxX - inset - length, y: rect.minY + inset))
        path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.minY + inset))
        path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.minY + inset + length))

        path.move(to: CGPoint(x: rect.minX + inset, y: rect.maxY - inset - length))
        path.addLine(to: CGPoint(x: rect.minX + inset, y: rect.maxY - inset))
        path.addLine(to: CGPoint(x: rect.minX + inset + length, y: rect.maxY - inset))

        path.move(to: CGPoint(x: rect.maxX - inset - length, y: rect.maxY - inset))
        path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.maxY - inset))
        path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.maxY - inset - length))

        return path
    }
}
