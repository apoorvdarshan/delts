import Combine
import PhotosUI
import SwiftData
import SwiftUI
import UIKit

struct CoachView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserProfile.updatedAt, order: .reverse) private var profiles: [UserProfile]
    @Query(sort: \CompletedWorkout.date, order: .reverse) private var completedWorkouts: [CompletedWorkout]

    @StateObject private var viewModel = CoachViewModel()
    @ObservedObject private var premium = PremiumStore.shared
    @FocusState private var inputFocused: Bool
    @State private var photoItem: PhotosPickerItem?
    @State private var showPhotosPicker = false
    @State private var showCamera = false
    @State private var showResetConfirm = false
    @State private var showPaywall = false

    private let typingID = "coach-typing-indicator"

    private var cameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        NavigationStack {
            transcript
                .deltsScreen()
                .navigationTitle("Coach")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showResetConfirm = true
                        } label: {
                            Image(systemName: "trash")
                        }
                        .tint(Color.deltsAccent)
                        .disabled(!viewModel.hasContent)
                        .accessibilityLabel("Reset chat")
                    }
                }
                .safeAreaInset(edge: .bottom) { inputBar }
                .onAppear { viewModel.configure(modelContext: modelContext) }
                .photosPicker(isPresented: $showPhotosPicker, selection: $photoItem, matching: .images)
                .fullScreenCover(isPresented: $showCamera) {
                    CoachCameraPicker { image in
                        viewModel.attachedImage = image
                    }
                    .ignoresSafeArea()
                }
                .confirmationDialog("Reset this chat?", isPresented: $showResetConfirm, titleVisibility: .visible) {
                    Button("Reset chat", role: .destructive) { viewModel.reset() }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("Clears the conversation. Your workouts and progress aren't affected.")
                }
                .sheet(isPresented: $showPaywall) {
                    PaywallView()
                }
                .onChange(of: photoItem) { _, newItem in
                    guard let newItem else { return }
                    Task {
                        if let data = try? await newItem.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            viewModel.attachedImage = image
                        }
                        photoItem = nil
                    }
                }
        }
    }

    // MARK: - Transcript

    private var transcript: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    if viewModel.messages.isEmpty {
                        emptyState
                    } else {
                        ForEach(viewModel.messages) { message in
                            CoachBubble(message: message)
                                .id(message.id)
                        }
                    }

                    if viewModel.isSending {
                        CoachTypingIndicator()
                            .id(typingID)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollDismissesKeyboard(.interactively)
            .simultaneousGesture(TapGesture().onEnded { inputFocused = false })
            .onChange(of: viewModel.messages.count) { scrollToEnd(proxy) }
            .onChange(of: viewModel.isSending) { scrollToEnd(proxy) }
            .onChange(of: inputFocused) { _, focused in
                guard focused else { return }
                // Keep the latest message visible above the keyboard. Re-scroll
                // once the keyboard finishes animating in so it lands correctly.
                scrollToEnd(proxy)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    scrollToEnd(proxy)
                }
            }
        }
    }

    private func scrollToEnd(_ proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.22)) {
            if viewModel.isSending {
                proxy.scrollTo(typingID, anchor: .bottom)
            } else if let last = viewModel.messages.last {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: "bubble.left.and.text.bubble.right.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(Color.deltsAccent)

                Text("Ask your Coach")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.deltsCharcoal)

                Text("Your Coach can see your profile, settings, body progress, and workout history. Ask anything — and attach a photo if it helps.")
                    .font(.subheadline)
                    .foregroundStyle(Color.deltsMutedText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 10) {
                ForEach(Self.suggestions, id: \.self) { suggestion in
                    Button {
                        viewModel.draft = suggestion
                        submit()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "sparkles")
                                .font(.footnote.weight(.bold))
                                .foregroundStyle(Color.deltsSecondaryAccent)
                            Text(suggestion)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.deltsCharcoal)
                                .multilineTextAlignment(.leading)
                            Spacer(minLength: 0)
                            Image(systemName: "arrow.up.right")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color.deltsMutedText)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.deltsPanel.opacity(0.22), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .stroke(Color.deltsHairline.opacity(0.32), lineWidth: 0.5)
                        )
                    }
                    .deltsPressable()
                }
            }
        }
        .padding(.top, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private static let suggestions = [
        "Plan a workout for me today",
        "How is my body progress trending?",
        "Give me tips to reach my goal",
        "Review my last workout"
    ]

    // MARK: - Input bar

    private var inputBar: some View {
        VStack(spacing: 10) {
            if !premium.isSubscribed {
                tasteBanner
            }

            if let image = viewModel.attachedImage {
                attachmentPreview(image)
            }

            HStack(alignment: .bottom, spacing: 10) {
                attachMenu

                TextField("Message Coach", text: $viewModel.draft, axis: .vertical)
                    .lineLimit(1...5)
                    .font(.body)
                    .foregroundStyle(Color.deltsCharcoal)
                    .focused($inputFocused)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(Color.deltsPanel.opacity(0.26), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.deltsHairline.opacity(0.34), lineWidth: 0.5)
                    )

                sendButton
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .deltsBottomActionBackground()
    }

    private var tasteBanner: some View {
        Button {
            showPaywall = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: premium.coachTasteRemaining > 0 ? "sparkles" : "lock.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.deltsAccent)

                Text(premium.coachTasteRemaining > 0
                     ? "\(premium.coachTasteRemaining) free message\(premium.coachTasteRemaining == 1 ? "" : "s") left"
                     : "Unlock unlimited Coach")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.deltsCharcoal)

                Spacer(minLength: 0)

                Text("Go Premium")
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(Color.deltsOnAccent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.deltsAccent, in: Capsule())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(Color.deltsAccent.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.deltsAccent.opacity(0.30), lineWidth: 0.5)
            }
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .deltsPressable()
        .accessibilityLabel("Delts Premium")
    }

    private var attachMenu: some View {
        Menu {
            if cameraAvailable {
                Button {
                    inputFocused = false
                    showCamera = true
                } label: {
                    Label("Camera", systemImage: "camera")
                }
            }
            Button {
                inputFocused = false
                showPhotosPicker = true
            } label: {
                Label("Photo Library", systemImage: "photo.on.rectangle")
            }
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color.deltsSecondaryAccent)
                .frame(width: 42, height: 42)
                .background(Color.deltsPanel.opacity(0.26), in: Circle())
                .overlay(Circle().stroke(Color.deltsHairline.opacity(0.34), lineWidth: 0.5))
        }
        .disabled(viewModel.isSending)
        .accessibilityLabel("Attach photo")
    }

    private var sendButton: some View {
        Button {
            submit()
        } label: {
            Image(systemName: "arrow.up")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color.deltsOnAccent)
                .frame(width: 42, height: 42)
                .background(viewModel.canSend ? Color.deltsAccent : Color.deltsPanel.opacity(0.4), in: Circle())
        }
        .disabled(!viewModel.canSend)
        .accessibilityLabel("Send")
    }

    private func attachmentPreview(_ image: UIImage) -> some View {
        HStack(spacing: 12) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text("Photo attached")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.deltsCharcoal)

            Spacer(minLength: 0)

            Button {
                viewModel.attachedImage = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.deltsMutedText)
            }
            .accessibilityLabel("Remove photo")
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.deltsPanel.opacity(0.22), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.deltsHairline.opacity(0.32), lineWidth: 0.5)
        )
    }

    // MARK: - Actions

    private func submit() {
        guard viewModel.canSend else { return }
        guard premium.canUseCoach else {
            inputFocused = false
            showPaywall = true
            return
        }
        inputFocused = false
        viewModel.send(contextProvider: buildContext) {
            // Consume the free taste only when the Coach actually replied, so
            // network failures never burn the lifetime allowance.
            PremiumStore.shared.consumeCoachTaste()
        }
    }

    private func buildContext() -> String {
        CoachContextBuilder.build(
            profile: profiles.first,
            workouts: completedWorkouts,
            snapshots: ProgressMetricStore.load()
        )
    }
}

// MARK: - Message bubble

private struct CoachBubble: View {
    let message: CoachMessage

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 44) }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 8) {
                if let image = message.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: 220, maxHeight: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                if !message.text.isEmpty {
                    Text(attributed)
                        .font(.body)
                        .foregroundStyle(textColor)
                        .multilineTextAlignment(.leading)
                        .textSelection(.enabled)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        .background(bubbleBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(borderColor, lineWidth: 0.5)
                        )
                }
            }

            if message.role == .model { Spacer(minLength: 44) }
        }
    }

    private var attributed: AttributedString {
        (try? AttributedString(
            markdown: message.text,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(message.text)
    }

    private var bubbleBackground: Color {
        if message.role == .user { return Color.deltsAccent }
        return message.isError ? Color.deltsWarning.opacity(0.16) : Color.deltsPanel.opacity(0.26)
    }

    private var textColor: Color {
        message.role == .user ? Color.deltsOnAccent : Color.deltsCharcoal
    }

    private var borderColor: Color {
        message.role == .user ? Color.clear : Color.deltsHairline.opacity(0.30)
    }
}

// MARK: - Typing indicator

private struct CoachTypingIndicator: View {
    @State private var phase = 0
    private let timer = Timer.publish(every: 0.35, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.deltsMutedText)
                    .frame(width: 7, height: 7)
                    .opacity(phase == index ? 1 : 0.3)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.deltsPanel.opacity(0.26), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.deltsHairline.opacity(0.30), lineWidth: 0.5)
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .onReceive(timer) { _ in
            phase = (phase + 1) % 3
        }
        .accessibilityLabel("Coach is typing")
    }
}

// MARK: - Camera picker

private struct CoachCameraPicker: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture, dismiss: { dismiss() })
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage) -> Void
        let dismiss: () -> Void

        init(onCapture: @escaping (UIImage) -> Void, dismiss: @escaping () -> Void) {
            self.onCapture = onCapture
            self.dismiss = dismiss
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                onCapture(image)
            }
            dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
    }
}
