import Combine
import Foundation
import SwiftData
import SwiftUI
import UIKit

@MainActor
final class CoachViewModel: ObservableObject {
    @Published var messages: [CoachMessage] = []
    @Published var draft: String = ""
    @Published var attachedImage: UIImage?
    @Published var isSending = false

    private let service = CoachService()
    private var modelContext: ModelContext?
    private var didHydrate = false

    var hasContent: Bool {
        !messages.isEmpty || attachedImage != nil || !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canSend: Bool {
        guard !isSending else { return false }
        return !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || attachedImage != nil
    }

    /// Connects the persistent store and loads saved history once.
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        guard !didHydrate else { return }
        didHydrate = true
        hydrate()
    }

    private func hydrate() {
        guard let modelContext else { return }
        let descriptor = FetchDescriptor<CoachMessageRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        guard let records = try? modelContext.fetch(descriptor) else { return }
        messages = records.map { record in
            CoachMessage(
                id: record.id,
                role: record.roleRaw == "model" ? .model : .user,
                text: record.text,
                image: record.imageData.flatMap(UIImage.init(data:)),
                isError: record.isError
            )
        }
    }

    /// Sends the current draft + attachment. `contextProvider` is evaluated now,
    /// on the main actor, so it can read SwiftData/app state safely.
    /// `onSuccess` fires only when the Coach actually replied — used to consume
    /// the free-taste allowance without burning it on failed sends.
    func send(contextProvider: () -> String, onSuccess: (() -> Void)? = nil) {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        let image = attachedImage
        guard !isSending, !text.isEmpty || image != nil else { return }

        let userMessage = CoachMessage(role: .user, text: text, image: image)
        messages.append(userMessage)
        persist(userMessage, imageData: image.flatMap { CoachService.jpegData($0) })
        draft = ""
        attachedImage = nil
        isSending = true

        let context = contextProvider()
        let history = messages
        let service = self.service

        Task { [weak self] in
            let result: CoachMessage
            var succeeded = false
            do {
                let reply = try await service.reply(systemContext: context, history: history)
                result = CoachMessage(role: .model, text: reply)
                succeeded = true
            } catch {
                let description = (error as? LocalizedError)?.errorDescription ?? "Something went wrong. Try again."
                result = CoachMessage(role: .model, text: description, isError: true)
            }
            guard let self else { return }
            self.messages.append(result)
            self.persist(result, imageData: nil)
            self.isSending = false
            if succeeded {
                onSuccess?()
            }
        }
    }

    func reset() {
        messages.removeAll()
        draft = ""
        attachedImage = nil
        isSending = false
        guard let modelContext else { return }
        try? modelContext.delete(model: CoachMessageRecord.self)
        try? modelContext.save()
    }

    private func persist(_ message: CoachMessage, imageData: Data?) {
        guard let modelContext else { return }
        let record = CoachMessageRecord(
            id: message.id,
            roleRaw: message.role == .model ? "model" : "user",
            text: message.text,
            isError: message.isError,
            imageData: imageData
        )
        modelContext.insert(record)
        try? modelContext.save()
    }
}
