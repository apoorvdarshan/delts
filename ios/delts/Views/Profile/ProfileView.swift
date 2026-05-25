import Foundation
import SwiftData
import SwiftUI

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserProfile.updatedAt, order: .reverse) private var profiles: [UserProfile]

    var body: some View {
        NavigationStack {
            Group {
                if let profile = profiles.first {
                    ProfileEditorView(profile: profile)
                } else {
                    ProfileLoadingView()
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .onDisappear {
                try? modelContext.save()
            }
        }
    }
}

private enum MeasurementSystem: String, CaseIterable, Hashable {
    case metric
    case imperial

    var title: String {
        switch self {
        case .metric:
            return "Metric"
        case .imperial:
            return "Imperial"
        }
    }
}

private enum AIProviderCatalog {
    static let customProvider = "Custom"
    static let customModel = "Custom model"

    static let providerNames = [
        "Gemini",
        "OpenAI",
        "Anthropic Claude",
        "xAI Grok",
        "OpenRouter",
        "Together AI",
        "Groq",
        "Hugging Face",
        "Fireworks AI",
        "DeepInfra",
        "Mistral",
        "Ollama",
        customProvider
    ]

    private static let modelsByProvider: [String: [String]] = [
        "Gemini": [
            "gemini-3.5-flash",
            "gemini-3.1-pro",
            "gemini-3-flash",
            "gemini-2.5-pro",
            "gemini-2.5-flash"
        ],
        "OpenAI": [
            "gpt-5.5",
            "gpt-5.4",
            "gpt-5.4-mini",
            "gpt-5.4-nano",
            "gpt-5",
            "gpt-5-mini",
            "gpt-4.1"
        ],
        "Anthropic Claude": [
            "claude-opus-4-7",
            "claude-sonnet-4-6",
            "claude-haiku-4-5-20251001",
            "claude-opus-4-6",
            "claude-sonnet-4-5"
        ],
        "xAI Grok": [
            "grok-4.3",
            "grok-4.3-latest",
            "grok-build-0.1",
            "grok-4"
        ],
        "OpenRouter": [
            "openrouter/auto",
            "google/gemini-2.5-pro",
            "anthropic/claude-sonnet-4.5",
            "openai/gpt-5",
            "x-ai/grok-4"
        ],
        "Together AI": [
            "moonshotai/Kimi-K2.5",
            "zai-org/GLM-5.1",
            "openai/gpt-oss-120b",
            "deepseek-ai/DeepSeek-R1",
            "Qwen/Qwen3-Coder-480B-A35B-Instruct-FP8"
        ],
        "Groq": [
            "openai/gpt-oss-120b",
            "openai/gpt-oss-20b",
            "meta-llama/llama-4-maverick-17b-128e-instruct",
            "meta-llama/llama-4-scout-17b-16e-instruct",
            "llama-3.3-70b-versatile"
        ],
        "Hugging Face": [
            "openai/gpt-oss-120b:fastest",
            "Qwen/Qwen3-235B-A22B:fastest",
            "deepseek-ai/DeepSeek-V3.1:fastest",
            "meta-llama/Llama-4-Maverick-17B-128E-Instruct:fastest"
        ],
        "Fireworks AI": [
            "accounts/fireworks/models/kimi-k2-instruct-0905",
            "accounts/fireworks/models/deepseek-v3p1",
            "accounts/fireworks/models/deepseek-r1",
            "accounts/fireworks/models/qwen3-235b-a22b",
            "accounts/fireworks/models/llama-v3p1-405b-instruct"
        ],
        "DeepInfra": [
            "deepseek-ai/DeepSeek-V3.2",
            "deepseek-ai/DeepSeek-R1",
            "Qwen/Qwen3-235B-A22B-Instruct-2507",
            "moonshotai/Kimi-K2-Instruct",
            "openai/gpt-oss-120b"
        ],
        "Mistral": [
            "mistral-large-latest",
            "mistral-medium-latest",
            "mistral-small-latest",
            "codestral-latest",
            "devstral-small-latest"
        ],
        "Ollama": [
            "llama4",
            "gemma3",
            "qwen3",
            "deepseek-r1",
            "llama3.3",
            "phi4"
        ]
    ]

    static func models(for provider: String) -> [String] {
        let baseModels = modelsByProvider[provider] ?? []
        return baseModels + [customModel]
    }

    static func defaultModel(for provider: String) -> String {
        modelsByProvider[provider]?.first ?? customModel
    }

    static func normalizedProvider(_ provider: String) -> String {
        providerNames.contains(provider) ? provider : customProvider
    }
}

private struct ProfileEditorView: View {
    @Bindable var profile: UserProfile
    @AppStorage("profile_measurement_system") private var measurementSystemRaw = MeasurementSystem.metric.rawValue
    @AppStorage("profile_custom_workout_split") private var customWorkoutSplit = ""
    @AppStorage("profile_ai_provider") private var aiProvider = "Gemini"
    @AppStorage("profile_ai_custom_provider") private var aiCustomProvider = ""
    @AppStorage("profile_ai_model") private var aiModel = AIProviderCatalog.defaultModel(for: "Gemini")
    @AppStorage("profile_ai_custom_model") private var aiCustomModel = ""
    @AppStorage("profile_ai_fallback_enabled") private var aiFallbackEnabled = false
    @AppStorage("profile_ai_fallback_provider") private var aiFallbackProvider = "OpenRouter"
    @AppStorage("profile_ai_fallback_custom_provider") private var aiFallbackCustomProvider = ""
    @AppStorage("profile_ai_fallback_model") private var aiFallbackModel = AIProviderCatalog.defaultModel(for: "OpenRouter")
    @AppStorage("profile_ai_fallback_custom_model") private var aiFallbackCustomModel = ""
    @State private var primaryAPIKey = LocalGeminiKeyStore.apiKey ?? ""
    @State private var fallbackAPIKey = LocalGeminiKeyStore.fallbackAPIKey ?? ""
    @State private var hasSavedPrimaryAPIKey = LocalGeminiKeyStore.apiKey != nil
    @State private var hasSavedFallbackAPIKey = LocalGeminiKeyStore.fallbackAPIKey != nil

    private let genderOptions = ["Male", "Female", "Non-binary", "Prefer not to say"]
    private let ageRange = 0...120
    private let frequencyOptions = Array(1...7)
    private let durationRange = 1...300
    private let aiProviderOptions = AIProviderCatalog.providerNames

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                identitySection
                goalSection
                aiSettingsSection
                scheduleSection
                strengthSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 18)
        }
        .deltsScreen()
        .contentMargins(.bottom, 110, for: .scrollContent)
        .scrollDismissesKeyboard(.interactively)
        .tint(Color.deltsAccent)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var identitySection: some View {
        ProfileSection(
            title: "About",
            subtitle: "Basic details used to shape plans.",
            systemImage: "person.text.rectangle"
        ) {
            ProfileRowStack {
                ProfileTextInputRow(title: "Name", systemImage: "person.fill", text: nameBinding)
                ProfileDivider()
                ProfileMenuPicker(
                    title: "Gender",
                    systemImage: "person.2",
                    selection: genderBinding,
                    options: genderOptions,
                    label: { $0 }
                )
                ProfileDivider()
                ProfileIntegerPickerRow(
                    title: "Age",
                    systemImage: "calendar",
                    value: ageBinding,
                    range: ageRange,
                    unit: "yr"
                )
                ProfileDivider()
                ProfileSegmentedPicker(
                    title: "Units",
                    systemImage: "ruler",
                    selection: measurementSystemBinding,
                    options: MeasurementSystem.allCases,
                    label: { $0.title }
                )
                ProfileDivider()
                ProfileHeightPickerRow(
                    title: "Height",
                    systemImage: "ruler",
                    system: measurementSystem,
                    centimeters: heightBinding
                )
                ProfileDivider()
                ProfileWeightPickerRow(
                    title: "Weight",
                    systemImage: "scalemass",
                    system: measurementSystem,
                    kilograms: weightBinding
                )
                ProfileDivider()
                ProfilePercentPickerRow(
                    title: "Current body fat",
                    systemImage: "percent",
                    value: currentBodyFatBinding,
                    range: 3...60
                )
                ProfileDivider()
                ProfilePercentPickerRow(
                    title: "Desired body fat",
                    systemImage: "scope",
                    value: desiredBodyFatBinding,
                    range: 3...45
                )
            }
        }
    }

    private var goalSection: some View {
        ProfileSection(
            title: "Goals",
            subtitle: "Set the training bias before plans are generated.",
            systemImage: "scope"
        ) {
            ProfileRowStack {
                ProfileSegmentedPicker(
                    title: "Experience",
                    systemImage: "chart.line.uptrend.xyaxis",
                    selection: experienceBinding,
                    options: ExperienceLevel.allCases,
                    label: { $0.title }
                )
                ProfileDivider()
                ProfileMenuPicker(
                    title: "Main goal",
                    systemImage: "flag.checkered",
                    selection: mainGoalBinding,
                    options: FitnessGoal.profileCases,
                    label: { $0.title }
                )
                ProfileDivider()
                ProfileMultiSelectMenuRow(
                    title: "Body parts",
                    systemImage: "figure.strengthtraining.functional",
                    options: BodyFocus.allCases,
                    selection: bodyFocusBinding,
                    label: { $0.title }
                )
                ProfileDivider()
                ProfileTextAreaRow(title: "Extra goals", systemImage: "text.alignleft", text: extraGoalsBinding)
                ProfileDivider()
                ProfileMultiSelectMenuRow(
                    title: "Issues",
                    systemImage: "exclamationmark.triangle.fill",
                    options: FitnessIssue.allCases,
                    selection: issuesBinding,
                    label: { $0.title }
                )
            }
        }
    }

    private var aiSettingsSection: some View {
        ProfileSection(
            title: "AI Settings",
            subtitle: "Provider, model, local key, and fallback.",
            systemImage: "key.fill",
            badge: hasSavedPrimaryAPIKey ? "Ready" : nil
        ) {
            ProfileRowStack {
                ProfileMenuPicker(
                    title: "Provider",
                    systemImage: "server.rack",
                    selection: aiProviderBinding,
                    options: aiProviderOptions,
                    label: { $0 }
                )
                if aiProvider == AIProviderCatalog.customProvider {
                    ProfileDivider()
                    ProfileTextInputRow(
                        title: "Provider name",
                        systemImage: "square.and.pencil",
                        text: aiCustomProviderBinding,
                        isTechnical: true
                    )
                }
                ProfileDivider()
                ProfileMenuPicker(
                    title: "Model",
                    systemImage: "cpu",
                    selection: aiModelBinding,
                    options: AIProviderCatalog.models(for: aiProvider),
                    label: { $0 }
                )
                if aiModel == AIProviderCatalog.customModel {
                    ProfileDivider()
                    ProfileTextInputRow(
                        title: "Model name",
                        systemImage: "text.cursor",
                        text: aiCustomModelBinding,
                        isTechnical: true
                    )
                }
                ProfileDivider()
                ProfileAPIKeyRow(
                    title: "API key",
                    apiKey: $primaryAPIKey,
                    hasSavedKey: hasSavedPrimaryAPIKey,
                    save: savePrimaryAPIKey,
                    clear: clearPrimaryAPIKey
                )
                ProfileDivider()
                ProfileToggleRow(
                    title: "Fallback",
                    systemImage: "arrow.triangle.2.circlepath",
                    isOn: $aiFallbackEnabled
                )
                if aiFallbackEnabled {
                    ProfileDivider()
                    ProfileMenuPicker(
                        title: "Fallback provider",
                        systemImage: "server.rack",
                        selection: aiFallbackProviderBinding,
                        options: aiProviderOptions,
                        label: { $0 }
                    )
                    if aiFallbackProvider == AIProviderCatalog.customProvider {
                        ProfileDivider()
                        ProfileTextInputRow(
                            title: "Fallback name",
                            systemImage: "square.and.pencil",
                            text: aiFallbackCustomProviderBinding,
                            isTechnical: true
                        )
                    }
                    ProfileDivider()
                    ProfileMenuPicker(
                        title: "Fallback model",
                        systemImage: "cpu",
                        selection: aiFallbackModelBinding,
                        options: AIProviderCatalog.models(for: aiFallbackProvider),
                        label: { $0 }
                    )
                    if aiFallbackModel == AIProviderCatalog.customModel {
                        ProfileDivider()
                        ProfileTextInputRow(
                            title: "Fallback model name",
                            systemImage: "text.cursor",
                            text: aiFallbackCustomModelBinding,
                            isTechnical: true
                        )
                    }
                    ProfileDivider()
                    ProfileAPIKeyRow(
                        title: "Fallback key",
                        apiKey: $fallbackAPIKey,
                        hasSavedKey: hasSavedFallbackAPIKey,
                        save: saveFallbackAPIKey,
                        clear: clearFallbackAPIKey
                    )
                }
            }
        }
    }

    private var scheduleSection: some View {
        ProfileSection(
            title: "Workout Setup",
            subtitle: "Tune how training fits into the week.",
            systemImage: "calendar.badge.clock"
        ) {
            ProfileRowStack {
                ProfileMenuPicker(
                    title: "Frequency",
                    systemImage: "calendar",
                    selection: frequencyBinding,
                    options: frequencyOptions,
                    label: { "\($0) days/week" }
                )
                ProfileDivider()
                ProfileMenuPicker(
                    title: "Workout split",
                    systemImage: "square.split.2x2",
                    selection: splitBinding,
                    options: WorkoutSplit.allCases,
                    label: { $0.title }
                )
                if profile.workoutSplit == .custom {
                    ProfileDivider()
                    ProfileTextInputRow(
                        title: "Custom split",
                        systemImage: "text.line.first.and.arrowtriangle.forward",
                        text: customWorkoutSplitBinding
                    )
                }
                ProfileDivider()
                ProfileIntegerPickerRow(
                    title: "Workout duration",
                    systemImage: "timer",
                    value: durationBinding,
                    range: durationRange,
                    unit: "min"
                )
                ProfileDivider()
                ProfileMultiSelectMenuRow(
                    title: "Equipment",
                    systemImage: "dumbbell.fill",
                    options: Equipment.allCases,
                    selection: equipmentBinding,
                    label: { $0.title }
                )
            }
        }
    }

    private var strengthSection: some View {
        ProfileSection(
            title: "1RM Numbers",
            subtitle: "Optional strength anchors for load guidance.",
            systemImage: "scalemass.fill"
        ) {
            ProfileRowStack {
                ProfileNumberInputRow(
                    title: "Bench Press",
                    systemImage: "figure.strengthtraining.traditional",
                    suffix: "kg",
                    value: benchBinding
                )
                ProfileDivider()
                ProfileNumberInputRow(
                    title: "Squat",
                    systemImage: "figure.strengthtraining.functional",
                    suffix: "kg",
                    value: squatBinding
                )
                ProfileDivider()
                ProfileNumberInputRow(
                    title: "Deadlift",
                    systemImage: "figure.core.training",
                    suffix: "kg",
                    value: deadliftBinding
                )
                ProfileDivider()
                ProfileNumberInputRow(
                    title: "Overhead Press",
                    systemImage: "arrow.up",
                    suffix: "kg",
                    value: overheadPressBinding
                )
            }
        }
    }

    private var aiProviderBinding: Binding<String> {
        Binding {
            AIProviderCatalog.normalizedProvider(aiProvider)
        } set: { newValue in
            aiProvider = newValue
            aiModel = AIProviderCatalog.defaultModel(for: newValue)
        }
    }

    private var aiCustomProviderBinding: Binding<String> {
        Binding {
            aiCustomProvider
        } set: { newValue in
            aiCustomProvider = newValue
        }
    }

    private var aiModelBinding: Binding<String> {
        Binding {
            let models = AIProviderCatalog.models(for: aiProvider)
            return models.contains(aiModel) ? aiModel : AIProviderCatalog.defaultModel(for: aiProvider)
        } set: { newValue in
            aiModel = newValue
        }
    }

    private var aiCustomModelBinding: Binding<String> {
        Binding {
            aiCustomModel
        } set: { newValue in
            aiCustomModel = newValue
        }
    }

    private var aiFallbackProviderBinding: Binding<String> {
        Binding {
            AIProviderCatalog.normalizedProvider(aiFallbackProvider)
        } set: { newValue in
            aiFallbackProvider = newValue
            aiFallbackModel = AIProviderCatalog.defaultModel(for: newValue)
        }
    }

    private var aiFallbackCustomProviderBinding: Binding<String> {
        Binding {
            aiFallbackCustomProvider
        } set: { newValue in
            aiFallbackCustomProvider = newValue
        }
    }

    private var aiFallbackModelBinding: Binding<String> {
        Binding {
            let models = AIProviderCatalog.models(for: aiFallbackProvider)
            return models.contains(aiFallbackModel) ? aiFallbackModel : AIProviderCatalog.defaultModel(for: aiFallbackProvider)
        } set: { newValue in
            aiFallbackModel = newValue
        }
    }

    private var aiFallbackCustomModelBinding: Binding<String> {
        Binding {
            aiFallbackCustomModel
        } set: { newValue in
            aiFallbackCustomModel = newValue
        }
    }

    private var genderBinding: Binding<String> {
        Binding {
            profile.gender
        } set: { newValue in
            profile.gender = newValue
            profile.updatedAt = Date()
        }
    }

    private var nameBinding: Binding<String> {
        Binding {
            profile.name
        } set: { newValue in
            profile.name = newValue
            profile.updatedAt = Date()
        }
    }

    private var extraGoalsBinding: Binding<String> {
        Binding {
            profile.extraGoals
        } set: { newValue in
            profile.extraGoals = newValue
            profile.updatedAt = Date()
        }
    }

    private var measurementSystem: MeasurementSystem {
        MeasurementSystem(rawValue: measurementSystemRaw) ?? .metric
    }

    private var measurementSystemBinding: Binding<MeasurementSystem> {
        Binding {
            measurementSystem
        } set: { newValue in
            measurementSystemRaw = newValue.rawValue
        }
    }

    private var ageBinding: Binding<Int> {
        Binding {
            profile.age
        } set: { newValue in
            profile.age = newValue
            profile.updatedAt = Date()
        }
    }

    private var heightBinding: Binding<Double> {
        doubleBinding(\.heightCM)
    }

    private var weightBinding: Binding<Double> {
        doubleBinding(\.currentWeightKG)
    }

    private var currentBodyFatBinding: Binding<Double> {
        doubleBinding(\.currentBodyFatPercentage)
    }

    private var desiredBodyFatBinding: Binding<Double> {
        doubleBinding(\.desiredBodyFatPercentage)
    }

    private var experienceBinding: Binding<ExperienceLevel> {
        Binding {
            profile.experienceLevel
        } set: { newValue in
            profile.experienceLevel = newValue
            profile.updatedAt = Date()
        }
    }

    private var mainGoalBinding: Binding<FitnessGoal> {
        Binding {
            profile.mainGoal
        } set: { newValue in
            profile.mainGoal = newValue
            profile.updatedAt = Date()
        }
    }

    private var bodyFocusBinding: Binding<Set<BodyFocus>> {
        Binding {
            profile.selectedBodyFocus
        } set: { newValue in
            profile.selectedBodyFocus = newValue
            profile.updatedAt = Date()
        }
    }

    private var frequencyBinding: Binding<Int> {
        Binding {
            profile.workoutFrequencyPerWeek
        } set: { newValue in
            profile.workoutFrequencyPerWeek = newValue
            profile.updatedAt = Date()
        }
    }

    private var splitBinding: Binding<WorkoutSplit> {
        Binding {
            profile.workoutSplit
        } set: { newValue in
            profile.workoutSplit = newValue
            profile.updatedAt = Date()
        }
    }

    private var customWorkoutSplitBinding: Binding<String> {
        Binding {
            customWorkoutSplit
        } set: { newValue in
            customWorkoutSplit = newValue
        }
    }

    private var durationBinding: Binding<Int> {
        Binding {
            profile.workoutDurationMinutes
        } set: { newValue in
            profile.workoutDurationMinutes = newValue
            profile.updatedAt = Date()
        }
    }

    private var equipmentBinding: Binding<Set<Equipment>> {
        Binding {
            profile.availableEquipment
        } set: { newValue in
            profile.availableEquipment = newValue
            profile.updatedAt = Date()
        }
    }

    private var benchBinding: Binding<Double> {
        doubleBinding(\.benchPressOneRM)
    }

    private var squatBinding: Binding<Double> {
        doubleBinding(\.squatOneRM)
    }

    private var deadliftBinding: Binding<Double> {
        doubleBinding(\.deadliftOneRM)
    }

    private var overheadPressBinding: Binding<Double> {
        doubleBinding(\.overheadPressOneRM)
    }

    private var issuesBinding: Binding<Set<FitnessIssue>> {
        Binding {
            profile.fitnessIssues
        } set: { newValue in
            profile.fitnessIssues = newValue
            profile.updatedAt = Date()
        }
    }

    private func doubleBinding(_ keyPath: ReferenceWritableKeyPath<UserProfile, Double>) -> Binding<Double> {
        Binding {
            profile[keyPath: keyPath]
        } set: { newValue in
            profile[keyPath: keyPath] = newValue
            profile.updatedAt = Date()
        }
    }

    private func savePrimaryAPIKey() {
        LocalGeminiKeyStore.save(primaryAPIKey)
        primaryAPIKey = LocalGeminiKeyStore.apiKey ?? ""
        hasSavedPrimaryAPIKey = LocalGeminiKeyStore.apiKey != nil
    }

    private func clearPrimaryAPIKey() {
        LocalGeminiKeyStore.clear()
        primaryAPIKey = ""
        hasSavedPrimaryAPIKey = false
    }

    private func saveFallbackAPIKey() {
        LocalGeminiKeyStore.saveFallback(fallbackAPIKey)
        fallbackAPIKey = LocalGeminiKeyStore.fallbackAPIKey ?? ""
        hasSavedFallbackAPIKey = LocalGeminiKeyStore.fallbackAPIKey != nil
    }

    private func clearFallbackAPIKey() {
        LocalGeminiKeyStore.clearFallback()
        fallbackAPIKey = ""
        hasSavedFallbackAPIKey = false
    }
}

private struct ProfileLoadingView: View {
    var body: some View {
        ScrollView {
            HStack(alignment: .center, spacing: 14) {
                ProgressView()
                    .tint(Color.deltsAccent)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Creating your default profile")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.deltsCharcoal)

                    Text("This only takes a moment.")
                        .font(.subheadline)
                        .foregroundStyle(Color.deltsMutedText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 18)
        }
        .deltsScreen()
        .contentMargins(.bottom, 110, for: .scrollContent)
    }
}

private struct ProfileSection<Content: View>: View {
    let title: String
    let subtitle: String?
    let systemImage: String
    let badge: String?
    let content: Content

    init(
        title: String,
        subtitle: String? = nil,
        systemImage: String,
        badge: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.badge = badge
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(title)
                    .font(.callout.weight(.bold))
                    .foregroundStyle(Color.deltsMutedText)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 10)

                if let badge {
                    Text(badge)
                        .font(.caption.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(Color.deltsAccent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.deltsAccent.opacity(0.10), in: Capsule())
                }
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, alignment: .leading)

            content
        }
    }
}

private struct ProfileRowStack<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(.horizontal, 14)
        .background(Color.deltsPanel.opacity(0.18), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.deltsHairline.opacity(0.22), lineWidth: 0.5)
        }
    }
}

private struct ProfileSectionPanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.deltsPanel.opacity(0.13), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.deltsHairline.opacity(0.24), lineWidth: 0.5)
        }
    }
}

private struct ProfileDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.deltsHairline.opacity(0.28))
            .frame(height: 0.5)
            .padding(.leading, 48)
    }
}

private struct ProfileFieldLabel: View {
    let title: String
    let systemImage: String
    var tint: Color = .deltsSecondaryAccent

    var body: some View {
        HStack(alignment: .center, spacing: 11) {
            Image(systemName: systemImage)
                .font(.system(size: 19, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(tint)
                .frame(width: 38, height: 34)

            Text(title)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.deltsCharcoal)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct ProfileFieldRow<Content: View>: View {
    let title: String
    let systemImage: String
    let tint: Color
    let content: Content
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(
        title: String,
        systemImage: String,
        tint: Color = .deltsSecondaryAccent,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 10) {
                ProfileFieldLabel(title: title, systemImage: systemImage, tint: tint)
                content
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        } else {
            HStack(alignment: .center, spacing: 12) {
                ProfileFieldLabel(title: title, systemImage: systemImage, tint: tint)
                    .layoutPriority(2)

                Spacer(minLength: 12)

                content
                    .layoutPriority(0)
            }
            .padding(.vertical, 9)
            .contentShape(Rectangle())
        }
    }
}

private struct ProfileControlBlock<Content: View>: View {
    let title: String
    let systemImage: String
    let tint: Color
    let content: Content

    init(
        title: String,
        systemImage: String,
        tint: Color = .deltsSecondaryAccent,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ProfileFieldLabel(title: title, systemImage: systemImage, tint: tint)

            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 12)
    }
}

private struct ProfileTextInputRow: View {
    let title: String
    let systemImage: String
    @Binding var text: String
    var isTechnical = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ProfileFieldRow(title: title, systemImage: systemImage) {
            TextField(title, text: $text)
                .textFieldStyle(.plain)
                .multilineTextAlignment(dynamicTypeSize.isAccessibilitySize ? .leading : .trailing)
                .foregroundStyle(Color.deltsCharcoal)
                .frame(minWidth: dynamicTypeSize.isAccessibilitySize ? 0 : 120)
                .textInputAutocapitalization(isTechnical ? .never : .words)
                .autocorrectionDisabled(isTechnical)
        }
    }
}

private struct ProfileTextAreaRow: View {
    let title: String
    let systemImage: String
    @Binding var text: String

    var body: some View {
        ProfileFieldRow(title: title, systemImage: systemImage) {
            TextField(title, text: $text)
                .textFieldStyle(.plain)
                .foregroundStyle(Color.deltsCharcoal)
                .multilineTextAlignment(.trailing)
                .lineLimit(1)
                .frame(minWidth: 130)
        }
    }
}

private struct ProfileNumberInputRow: View {
    let title: String
    let systemImage: String
    let suffix: String
    @Binding var value: Double
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ProfileFieldRow(title: title, systemImage: systemImage) {
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                TextField(title, value: $value, format: .number.precision(.fractionLength(1)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(dynamicTypeSize.isAccessibilitySize ? .leading : .trailing)
                    .textFieldStyle(.plain)
                    .font(.body.monospacedDigit())
                    .foregroundStyle(Color.deltsCharcoal)

                Text(suffix)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.deltsMutedText)
            }
            .frame(width: dynamicTypeSize.isAccessibilitySize ? nil : 128, alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .trailing)
        }
    }
}

private struct ProfileIntegerPickerRow: View {
    let title: String
    let systemImage: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let unit: String
    @State private var isPickerPresented = false

    var body: some View {
        ProfileFieldRow(title: title, systemImage: systemImage) {
            Button {
                isPickerPresented = true
            } label: {
                ProfileMenuValueLabel(text: "\(value.clamped(to: range)) \(unit)")
            }
            .deltsPressable()
            .sheet(isPresented: $isPickerPresented) {
                ProfileIntegerWheelSheet(
                    title: title,
                    initialValue: value,
                    range: range,
                    unit: unit
                ) { newValue in
                    value = newValue
                }
            }
        }
    }
}

private struct ProfileHeightPickerRow: View {
    let title: String
    let systemImage: String
    let system: MeasurementSystem
    @Binding var centimeters: Double
    @State private var isPickerPresented = false

    private var displayText: String {
        switch system {
        case .metric:
            return "\(profileFormatDecimal(centimeters)) cm"
        case .imperial:
            let parts = profileImperialHeightParts(fromCentimeters: centimeters)
            return "\(parts.feet) ft \(parts.inches) in"
        }
    }

    var body: some View {
        ProfileFieldRow(title: title, systemImage: systemImage) {
            Button {
                isPickerPresented = true
            } label: {
                ProfileMenuValueLabel(text: displayText)
            }
            .deltsPressable()
            .sheet(isPresented: $isPickerPresented) {
                switch system {
                case .metric:
                    ProfileDecimalWheelSheet(
                        title: title,
                        initialValue: centimeters,
                        wholeRange: 120...230,
                        unit: "cm"
                    ) { newValue in
                        centimeters = newValue
                    }
                case .imperial:
                    ProfileImperialHeightWheelSheet(
                        initialCentimeters: centimeters
                    ) { newCentimeters in
                        centimeters = newCentimeters
                    }
                }
            }
        }
    }
}

private struct ProfileWeightPickerRow: View {
    let title: String
    let systemImage: String
    let system: MeasurementSystem
    @Binding var kilograms: Double
    @State private var isPickerPresented = false

    private var displayValue: Double {
        switch system {
        case .metric:
            return kilograms
        case .imperial:
            return kilograms * 2.2046226218
        }
    }

    private var unit: String {
        system == .metric ? "kg" : "lb"
    }

    private var wholeRange: ClosedRange<Int> {
        system == .metric ? 30...250 : 66...551
    }

    private var displayText: String {
        "\(profileFormatDecimal(displayValue)) \(unit)"
    }

    var body: some View {
        ProfileFieldRow(title: title, systemImage: systemImage) {
            Button {
                isPickerPresented = true
            } label: {
                ProfileMenuValueLabel(text: displayText)
            }
            .deltsPressable()
            .sheet(isPresented: $isPickerPresented) {
                ProfileDecimalWheelSheet(
                    title: title,
                    initialValue: displayValue,
                    wholeRange: wholeRange,
                    unit: unit
                ) { newDisplayValue in
                    switch system {
                    case .metric:
                        kilograms = newDisplayValue
                    case .imperial:
                        kilograms = newDisplayValue / 2.2046226218
                    }
                }
            }
        }
    }
}

private struct ProfilePercentPickerRow: View {
    let title: String
    let systemImage: String
    @Binding var value: Double
    let range: ClosedRange<Int>
    @State private var isPickerPresented = false

    var body: some View {
        ProfileFieldRow(title: title, systemImage: systemImage) {
            Button {
                isPickerPresented = true
            } label: {
                ProfileMenuValueLabel(text: "\(profileFormatDecimal(value))%")
            }
            .deltsPressable()
            .sheet(isPresented: $isPickerPresented) {
                ProfileDecimalWheelSheet(
                    title: title,
                    initialValue: value,
                    wholeRange: range,
                    unit: "%"
                ) { newValue in
                    value = newValue
                }
            }
        }
    }
}

private struct ProfileIntegerWheelSheet: View {
    let title: String
    let unit: String
    let options: [Int]
    let onSave: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedValue: Int

    init(
        title: String,
        initialValue: Int,
        range: ClosedRange<Int>,
        unit: String,
        onSave: @escaping (Int) -> Void
    ) {
        self.title = title
        self.unit = unit
        self.options = Array(range)
        self.onSave = onSave
        _selectedValue = State(initialValue: initialValue.clamped(to: range))
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text("\(selectedValue) \(unit)")
                    .font(.title2.monospacedDigit().weight(.bold))
                    .foregroundStyle(Color.deltsCharcoal)
                    .frame(maxWidth: .infinity, alignment: .center)

                ProfileWheelColumn(title: title, selection: $selectedValue, values: options) { "\($0)" }
                    .frame(height: 190)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 18)
            .background(DeltsBackground())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onSave(selectedValue)
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
        .presentationDetents([.height(320), .medium])
        .presentationDragIndicator(.visible)
    }
}

private struct ProfileDecimalWheelSheet: View {
    let title: String
    let unit: String
    let wholeOptions: [Int]
    let onSave: (Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var whole: Int
    @State private var decimal: Int

    init(
        title: String,
        initialValue: Double,
        wholeRange: ClosedRange<Int>,
        unit: String,
        onSave: @escaping (Double) -> Void
    ) {
        let parts = profileDecimalParts(for: initialValue, range: wholeRange)
        self.title = title
        self.unit = unit
        self.wholeOptions = Array(wholeRange)
        self.onSave = onSave
        _whole = State(initialValue: parts.whole)
        _decimal = State(initialValue: parts.decimal)
    }

    private var selectedValue: Double {
        Double(whole) + (Double(decimal) / 10)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text("\(profileFormatDecimal(selectedValue)) \(unit)")
                    .font(.title2.monospacedDigit().weight(.bold))
                    .foregroundStyle(Color.deltsCharcoal)
                    .frame(maxWidth: .infinity, alignment: .center)

                HStack(spacing: 10) {
                    ProfileWheelColumn(title: "Whole", selection: $whole, values: wholeOptions) { "\($0)" }
                    ProfileWheelColumn(title: "Decimal", selection: $decimal, values: Array(0...9)) { ".\($0)" }

                    Text(unit)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.deltsMutedText)
                        .frame(width: 48)
                }
                .frame(height: 190)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 18)
            .background(DeltsBackground())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onSave(selectedValue)
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
        .presentationDetents([.height(340), .medium])
        .presentationDragIndicator(.visible)
    }
}

private struct ProfileImperialHeightWheelSheet: View {
    let onSave: (Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var feet: Int
    @State private var inches: Int

    init(initialCentimeters: Double, onSave: @escaping (Double) -> Void) {
        let parts = profileImperialHeightParts(fromCentimeters: initialCentimeters)
        self.onSave = onSave
        _feet = State(initialValue: parts.feet)
        _inches = State(initialValue: parts.inches)
    }

    private var selectedInches: Double {
        Double((feet * 12) + inches)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text("\(feet) ft \(inches) in")
                    .font(.title2.monospacedDigit().weight(.bold))
                    .foregroundStyle(Color.deltsCharcoal)
                    .frame(maxWidth: .infinity, alignment: .center)

                HStack(spacing: 8) {
                    ProfileWheelColumn(title: "Feet", selection: $feet, values: Array(3...8)) { "\($0)" }
                    ProfileWheelColumn(title: "Inches", selection: $inches, values: Array(0...11)) { "\($0)" }
                }
                .frame(height: 190)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 18)
            .background(DeltsBackground())
            .navigationTitle("Height")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onSave(selectedInches * 2.54)
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
        .presentationDetents([.height(340), .medium])
        .presentationDragIndicator(.visible)
    }
}

private struct ProfileWheelColumn: View {
    let title: String
    @Binding var selection: Int
    let values: [Int]
    let label: (Int) -> String

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.deltsMutedText)

            Picker(title, selection: $selection) {
                ForEach(values, id: \.self) { value in
                    Text(label(value))
                        .font(.title3.monospacedDigit().weight(.semibold))
                        .tag(value)
                }
            }
            .pickerStyle(.wheel)
            .labelsHidden()
        }
        .frame(maxWidth: .infinity)
        .background(Color.deltsPanel.opacity(0.18), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.deltsHairline.opacity(0.24), lineWidth: 0.5)
        }
    }
}

private func profileFormatDecimal(_ value: Double) -> String {
    value.formatted(.number.precision(.fractionLength(1)))
}

private func profileDecimalParts(for value: Double, range: ClosedRange<Int>) -> (whole: Int, decimal: Int) {
    let minimumTenths = range.lowerBound * 10
    let maximumTenths = (range.upperBound * 10) + 9
    let tenths = Int((value * 10).rounded()).clamped(to: minimumTenths...maximumTenths)
    let whole = (tenths / 10).clamped(to: range)
    let decimal = tenths % 10
    return (whole, decimal)
}

private func profileImperialHeightParts(fromCentimeters centimeters: Double) -> (feet: Int, inches: Int) {
    let totalInches = Int((centimeters / 2.54).rounded()).clamped(to: 36...107)
    let feet = (totalInches / 12).clamped(to: 3...8)
    let inches = (totalInches - (feet * 12)).clamped(to: 0...11)
    return (feet, inches)
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

private struct ProfileMenuPicker<Option: Hashable>: View {
    let title: String
    let systemImage: String
    @Binding var selection: Option
    let options: [Option]
    let label: (Option) -> String

    var body: some View {
        ProfileFieldRow(title: title, systemImage: systemImage) {
            Menu {
                ForEach(options, id: \.self) { option in
                    Button {
                        selection = option
                    } label: {
                        if option == selection {
                            Label {
                                ProfileMenuOptionText(text: label(option))
                            } icon: {
                                Image(systemName: "checkmark")
                            }
                        } else {
                            ProfileMenuOptionText(text: label(option))
                        }
                    }
                }
            } label: {
                ProfileMenuValueLabel(text: label(selection))
            }
            .deltsPressable()
        }
    }
}

private struct ProfileMenuOptionText: View {
    let text: String

    private var nonWrappingText: String {
        text
            .replacingOccurrences(of: " ", with: "\u{00A0}")
            .map(String.init)
            .joined(separator: "\u{2060}")
    }

    var body: some View {
        Text(nonWrappingText)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .accessibilityLabel(text)
    }
}

private struct ProfileMenuValueLabel: View {
    let text: String

    var body: some View {
        HStack(spacing: 7) {
            Text(text)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.deltsMutedText)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .multilineTextAlignment(.trailing)

            Image(systemName: "chevron.up.chevron.down")
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color.deltsMutedText)
        }
        .frame(minWidth: 72, maxWidth: 178, minHeight: 38, alignment: .trailing)
    }
}

private struct ProfileSegmentedPicker<Option: Hashable>: View {
    let title: String
    let systemImage: String
    @Binding var selection: Option
    let options: [Option]
    let label: (Option) -> String

    var body: some View {
        ProfileFieldRow(title: title, systemImage: systemImage) {
            Menu {
                ForEach(options, id: \.self) { option in
                    Button {
                        selection = option
                    } label: {
                        if option == selection {
                            Label(label(option), systemImage: "checkmark")
                        } else {
                            Text(label(option))
                        }
                    }
                }
            } label: {
                ProfileMenuValueLabel(text: label(selection))
            }
            .deltsPressable()
        }
    }
}

private struct ProfileAPIKeyRow: View {
    let title: String
    @Binding var apiKey: String
    let hasSavedKey: Bool
    let save: () -> Void
    let clear: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        ProfileFieldRow(
            title: title,
            systemImage: hasSavedKey ? "checkmark.seal.fill" : "key.fill",
            tint: hasSavedKey ? .deltsAccent : .deltsSecondaryAccent
        ) {
            HStack(spacing: 8) {
                SecureField(hasSavedKey ? "Saved" : "Paste key", text: $apiKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(.password)
                    .focused($isFocused)
                    .submitLabel(.done)
                    .onSubmit(save)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.deltsCharcoal)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(1)
                    .frame(minWidth: 112)

                Button(action: save) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 15, weight: .bold))
                        .frame(width: 32, height: 32)
                }
                .accessibilityLabel("Save API key")

                Button(action: clear) {
                    Image(systemName: "trash")
                        .font(.system(size: 15, weight: .bold))
                        .frame(width: 32, height: 32)
                }
                .accessibilityLabel("Clear API key")
            }
            .foregroundStyle(Color.deltsMutedText)
        }
    }
}

private struct ProfileToggleRow: View {
    let title: String
    let systemImage: String
    @Binding var isOn: Bool

    var body: some View {
        ProfileFieldRow(title: title, systemImage: systemImage) {
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
    }
}

private struct ProfileMultiSelectMenuRow<Option: Hashable>: View {
    let title: String
    let systemImage: String
    let options: [Option]
    @Binding var selection: Set<Option>
    let label: (Option) -> String

    private var summary: String {
        let selectedTitles = options.filter { selection.contains($0) }.map(label)
        if selectedTitles.isEmpty {
            return "None"
        }
        if selectedTitles.count <= 2 {
            return selectedTitles.joined(separator: ", ")
        }
        return "\(selectedTitles.count) selected"
    }

    var body: some View {
        ProfileFieldRow(title: title, systemImage: systemImage) {
            Menu {
                ForEach(options, id: \.self) { option in
                    Button {
                        var updatedSelection = selection
                        if updatedSelection.contains(option) {
                            updatedSelection.remove(option)
                        } else {
                            updatedSelection.insert(option)
                        }
                        selection = updatedSelection
                    } label: {
                        if selection.contains(option) {
                            Label(label(option), systemImage: "checkmark")
                        } else {
                            Text(label(option))
                        }
                    }
                }
            } label: {
                ProfileMenuValueLabel(text: summary)
            }
            .deltsPressable()
        }
    }
}

private struct ProfileChoiceRail<Option: Hashable>: View {
    @Binding var selection: Option
    let options: [Option]
    let label: (Option) -> String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(options, id: \.self) { option in
                    let isSelected = option == selection

                    Button {
                        let animation: Animation? = reduceMotion ? nil : .snappy(duration: 0.18)
                        withAnimation(animation) {
                            selection = option
                        }
                    } label: {
                        Text(label(option))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(isSelected ? Color.deltsOnAccent : Color.deltsCharcoal)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                            .padding(.horizontal, 13)
                            .frame(minWidth: 92, minHeight: 40)
                            .background(
                                isSelected ? Color.deltsAccent : Color.deltsPanel.opacity(0.24),
                                in: RoundedRectangle(cornerRadius: 15, style: .continuous)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 15, style: .continuous)
                                    .stroke(Color.deltsHairline.opacity(isSelected ? 0.18 : 0.30), lineWidth: 0.5)
                            }
                            .contentShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                    }
                    .deltsPressable()
                    .accessibilityLabel(label(option))
                    .accessibilityValue(isSelected ? "Selected" : "Not selected")
                }
            }
            .padding(.horizontal, 1)
        }
    }
}

private struct ProfileCountSummaryRow: View {
    let title: String
    let systemImage: String
    let value: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ProfileFieldLabel(title: title, systemImage: systemImage)

            Spacer(minLength: 12)

            Text(value)
                .font(.headline.monospacedDigit().weight(.bold))
                .foregroundStyle(Color.deltsAccent)
        }
        .padding(.vertical, 8)
    }
}

private struct ProfileChecklistGrid<Option: Identifiable & Hashable>: View {
    let options: [Option]
    @Binding var selection: Set<Option>
    let title: (Option) -> String
    let icon: (Option) -> String
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var columns: [GridItem] {
        [
            GridItem(
                .adaptive(minimum: dynamicTypeSize.isAccessibilitySize ? 260 : 150),
                spacing: 10,
                alignment: .top
            )
        ]
    }

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            ForEach(options) { option in
                let isSelected = selection.contains(option)

                Button {
                    withAnimation(.easeInOut(duration: 0.16)) {
                        var updatedSelection = selection
                        if isSelected {
                            updatedSelection.remove(option)
                        } else {
                            updatedSelection.insert(option)
                        }
                        selection = updatedSelection
                    }
                } label: {
                    ProfileChecklistChip(
                        title: title(option),
                        systemImage: icon(option),
                        isSelected: isSelected
                    )
                }
                .deltsPressable()
                .accessibilityValue(isSelected ? "Selected" : "Not selected")
                .accessibilityHint(isSelected ? "Double tap to remove." : "Double tap to select.")
            }
        }
    }
}

private struct ProfileChecklistChip: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(alignment: .center, spacing: 9) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(isSelected ? Color.deltsAccent : Color.deltsSecondaryAccent)
                .frame(width: 28, height: 28)

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.deltsCharcoal)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                .minimumScaleFactor(0.86)
                .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: isSelected ? "checkmark" : "plus")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(isSelected ? Color.deltsAccent : Color.deltsHairline)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
        .background(
            (isSelected ? Color.deltsAccent.opacity(0.11) : Color.deltsPanel.opacity(0.14)),
            in: Capsule()
        )
        .overlay {
            Capsule()
                .stroke(
                    isSelected ? Color.deltsAccent.opacity(0.38) : Color.deltsHairline.opacity(0.22),
                    lineWidth: 0.75
                )
        }
    }
}
