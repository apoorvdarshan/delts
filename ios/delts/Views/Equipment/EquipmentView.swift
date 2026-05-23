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
            VStack(alignment: .leading, spacing: 22) {
                scannerShell

                if let profile = profiles.first {
                    equipmentSection(for: profile)
                } else {
                    missingProfile
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
            .frame(maxWidth: 680, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .deltsScreen()
        .tint(Color.deltsAccent)
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
            subtitle: "Rack photo or manual check-in",
            selectedCount: selectedEquipmentCount,
            statusText: scannerStatusText
        ) {
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                EquipmentScannerControlLabel(
                    title: "Photo",
                    systemImage: "camera.viewfinder",
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
        VStack(alignment: .leading, spacing: 14) {
            DeltsSectionHeader(
                title: "Available Equipment",
                detail: "\(profile.availableEquipment.count) selected"
            )

            EquipmentGrid(selection: equipmentBinding(for: profile))
        }
    }

    private var missingProfile: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.deltsAccent)
                .frame(width: 34, height: 34)
                .background(Color.deltsAccent.opacity(0.13), in: Circle())

            Text("Profile is being created. Reopen this tab in a moment.")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.deltsMutedText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.deltsPanel.opacity(0.28), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.deltsHairline.opacity(0.42), lineWidth: 0.5)
        }
        .accessibilityElement(children: .combine)
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
            .padding(.top, 8)
            .padding(.bottom, 24)
            .frame(maxWidth: 680, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .deltsScreen()
        .tint(Color.deltsAccent)
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
            subtitle: "Rack photo or manual check-in",
            selectedCount: nil,
            statusText: statusText
        ) {
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                EquipmentScannerControlLabel(
                    title: "Photo",
                    systemImage: "camera.viewfinder",
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
    @Environment(\.colorScheme) private var colorScheme

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
                .stroke(Color.deltsHairline.opacity(0.48), style: StrokeStyle(lineWidth: 2.25, lineCap: .round, lineJoin: .round))
                .padding(6)

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 14) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(title)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Color.deltsCharcoal)
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)

                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(Color.deltsMutedText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }

                    Spacer(minLength: 12)

                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.deltsAccent)
                        .frame(width: 42, height: 42)
                        .background(Color.deltsAccent.opacity(0.12), in: Circle())
                        .overlay {
                            Circle()
                                .stroke(Color.deltsHairline.opacity(0.34), lineWidth: 0.5)
                        }
                        .accessibilityHidden(true)
                }

                EquipmentScannerStatusPill(
                    selectedCount: selectedCount,
                    statusText: statusText
                )

                Spacer(minLength: 16)

                ZStack {
                    Circle()
                        .stroke(Color.deltsHairline.opacity(0.26), lineWidth: 1)
                        .frame(width: 112, height: 112)

                    Circle()
                        .fill(Color.deltsSecondaryAccent.opacity(0.08))
                        .frame(width: 82, height: 82)

                    Image(systemName: "viewfinder")
                        .font(.system(size: 52, weight: .thin))
                        .foregroundStyle(Color.deltsCharcoal.opacity(0.18))
                        .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity)

                Spacer(minLength: 76)
            }
            .padding(20)

            VStack {
                Spacer()

                HStack(spacing: 10) {
                    primaryControl
                    secondaryControl
                }
                .padding(7)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 23, style: .continuous))
                .background(Color.deltsPanel.opacity(0.22), in: RoundedRectangle(cornerRadius: 23, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 23, style: .continuous)
                        .stroke(Color.deltsHairline.opacity(0.42), lineWidth: 0.5)
                }
                .padding(13)
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1.12, contentMode: .fit)
        .frame(minHeight: 280)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.deltsHairline.opacity(0.45), lineWidth: 0.5)
        }
        .shadow(color: Color.deltsHairline.opacity(colorScheme == .dark ? 0.18 : 0.16), radius: 18, x: 0, y: 12)
    }

    private var scannerBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color.deltsCard.opacity(colorScheme == .dark ? 0.86 : 0.70),
                Color.deltsPanel.opacity(colorScheme == .dark ? 0.54 : 0.42),
                Color.deltsSecondaryAccent.opacity(0.10),
                Color.deltsAccent.opacity(0.07)
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
        HStack(spacing: 8) {
            Image(systemName: statusImage)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(statusTint)

            if let selectedCount {
                Text("\(selectedCount) selected")
                    .foregroundStyle(Color.deltsCharcoal)

                Capsule()
                    .fill(Color.deltsHairline.opacity(0.48))
                    .frame(width: 1, height: 12)
            }

            Text(statusText)
                .foregroundStyle(Color.deltsMutedText)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(.regularMaterial, in: Capsule())
        .background(Color.deltsCard.opacity(0.26), in: Capsule())
        .overlay {
            Capsule()
                .stroke(Color.deltsHairline.opacity(0.36), lineWidth: 0.5)
        }
        .accessibilityLabel(label)
    }

    private var label: String {
        if let selectedCount {
            return "\(selectedCount) selected, \(statusText)"
        }
        return statusText
    }

    private var statusImage: String {
        switch statusText {
        case "Scan complete":
            return "checkmark.circle.fill"
        case "Reading photo":
            return "camera.metering.center.weighted"
        case "Manual mode":
            return "checklist"
        default:
            return "circle.fill"
        }
    }

    private var statusTint: Color {
        switch statusText {
        case "Scan complete", "Manual mode":
            return Color.deltsSecondaryAccent
        case "Reading photo":
            return Color.deltsAccent
        default:
            return Color.deltsMutedText
        }
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
        .foregroundStyle(isProminent ? Color.deltsOnAccent : Color.deltsCharcoal)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 11)
        .padding(.horizontal, 12)
        .background(backgroundColor, in: Capsule())
        .overlay {
            Capsule()
                .stroke(borderColor, lineWidth: 0.5)
        }
        .contentShape(Capsule())
    }

    private var backgroundColor: Color {
        isProminent ? Color.deltsAccent : Color.deltsSecondaryAccent.opacity(0.14)
    }

    private var borderColor: Color {
        isProminent ? Color.deltsAccent.opacity(0.35) : Color.deltsHairline.opacity(0.42)
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
