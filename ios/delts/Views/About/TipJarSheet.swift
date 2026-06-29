import StoreKit
import SwiftUI

/// "Support Delts" tip jar — optional one-off tips via StoreKit. The app
/// stays fully free; this unlocks nothing.
struct TipJarSheet: View {
    @ObservedObject private var store = TipStore.shared
    @Environment(\.dismiss) private var dismiss

    private let emoji = ["☕️", "🥪", "🎉", "💚"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    header

                    if store.showThanks {
                        thanks
                    } else if store.isLoading && store.tips.isEmpty {
                        ProgressView()
                            .tint(Color.deltsAccent)
                            .frame(maxWidth: .infinity, minHeight: 140)
                    } else if store.tips.isEmpty {
                        unavailable
                    } else {
                        VStack(spacing: 12) {
                            ForEach(Array(store.tips.enumerated()), id: \.element.id) { index, product in
                                tipRow(product, emoji: emoji[min(index, emoji.count - 1)])
                            }
                        }

                        Text("Tips are one-time and unlock nothing — the whole app stays free either way.")
                            .font(.caption)
                            .foregroundStyle(Color.deltsMutedText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
            .background(DeltsBackground())
            .navigationTitle("Support Delts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.deltsAccent)
                }
            }
            .alert("Something went wrong", isPresented: errorBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(store.lastErrorMessage ?? "")
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart.fill")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(Color.deltsAccent)
                .frame(width: 64, height: 64)
                .background(Color.deltsAccent.opacity(0.12), in: Circle())

            Text("Delts is free, forever")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.deltsCharcoal)

            Text("No ads, no account, no subscriptions. If Delts is useful to you, a small tip helps keep it going — completely optional.")
                .font(.subheadline)
                .foregroundStyle(Color.deltsMutedText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 6)
    }

    private func tipRow(_ product: Product, emoji: String) -> some View {
        Button {
            Task { await store.purchase(product) }
        } label: {
            HStack(spacing: 14) {
                Text(emoji)
                    .font(.title2)
                    .frame(width: 30)

                Text(product.displayName)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.deltsCharcoal)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 8)

                Text(product.displayPrice)
                    .font(.headline.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(Color.deltsOnAccent)
                    .padding(.horizontal, 14)
                    .frame(height: 36)
                    .background(Color.deltsAccent, in: Capsule())
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 60)
            .background(Color.deltsPanel.opacity(0.18), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.deltsHairline.opacity(0.24), lineWidth: 0.5)
            }
            .opacity(store.isPurchasing ? 0.6 : 1)
        }
        .buttonStyle(.plain)
        .deltsPressable()
        .disabled(store.isPurchasing)
    }

    private var thanks: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(Color.deltsAccent)
            Text("Thank you! 💚")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.deltsCharcoal)
            Text("Your support genuinely means a lot.")
                .font(.subheadline)
                .foregroundStyle(Color.deltsMutedText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 160)
    }

    private var unavailable: some View {
        VStack(spacing: 8) {
            Text("Tips aren't available right now")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.deltsCharcoal)
            Text("Please check your connection and try again later.")
                .font(.caption)
                .foregroundStyle(Color.deltsMutedText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 140)
    }

    private var errorBinding: Binding<Bool> {
        Binding {
            store.lastErrorMessage != nil
        } set: { newValue in
            if !newValue { store.lastErrorMessage = nil }
        }
    }
}
