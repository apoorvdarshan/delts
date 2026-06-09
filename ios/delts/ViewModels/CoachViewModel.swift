import Combine
import Foundation
import SwiftUI
import UIKit

@MainActor
final class CoachViewModel: ObservableObject {
    @Published var messages: [CoachMessage] = []
    @Published var draft: String = ""
    @Published var attachedImage: UIImage?
    @Published var isSending = false

    private let service = CoachService()

    var hasContent: Bool {
        !messages.isEmpty || attachedImage != nil || !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canSend: Bool {
        guard !isSending else { return false }
        return !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || attachedImage != nil
    }

    /// Sends the current draft + attachment. `contextProvider` is evaluated now,
    /// on the main actor, so it can read SwiftData/app state safely.
    func send(contextProvider: () -> String) {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        let image = attachedImage
        guard !isSending, !text.isEmpty || image != nil else { return }

        messages.append(CoachMessage(role: .user, text: text, image: image))
        draft = ""
        attachedImage = nil
        isSending = true

        let context = contextProvider()
        let history = messages
        let service = self.service

        Task { [weak self] in
            do {
                let reply = try await service.reply(systemContext: context, history: history)
                self?.messages.append(CoachMessage(role: .model, text: reply))
            } catch {
                let description = (error as? LocalizedError)?.errorDescription ?? "Something went wrong. Try again."
                self?.messages.append(CoachMessage(role: .model, text: description, isError: true))
            }
            self?.isSending = false
        }
    }

    func reset() {
        messages.removeAll()
        draft = ""
        attachedImage = nil
        isSending = false
    }
}
