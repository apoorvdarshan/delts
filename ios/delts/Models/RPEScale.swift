import Foundation

enum RPEScale: String, CaseIterable, Hashable {
    case strength
    case cr10
    case borg

    static let storageKey = "profile_rpe_scale"

    var title: String {
        switch self {
        case .strength: return "Strength 1-10"
        case .cr10: return "CR10 0-10"
        case .borg: return "Borg 6-20"
        }
    }

    var inputPlaceholder: String {
        switch self {
        case .strength: return "1-10"
        case .cr10: return "0-10"
        case .borg: return "6-20"
        }
    }

    var allowsDecimalInput: Bool {
        self != .borg
    }

    var inputRange: ClosedRange<Double> {
        switch self {
        case .strength:
            return 1...10
        case .cr10:
            return 0...10
        case .borg:
            return 6...20
        }
    }

    func sanitizedInput(_ proposedValue: String, previousValue: String = "") -> String {
        let normalizedSeparators = proposedValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        guard !normalizedSeparators.isEmpty else { return "" }

        let filtered = filteredInput(normalizedSeparators)
        guard !filtered.isEmpty else { return previousValue }

        let numericText = filtered.hasSuffix(".") ? String(filtered.dropLast()) : filtered
        guard let value = Double(numericText) else { return previousValue }

        if value > inputRange.upperBound {
            return formattedBoundary(inputRange.upperBound)
        }
        if value < inputRange.lowerBound, !isPossibleRangePrefix(filtered) {
            return previousValue
        }

        return filtered
    }

    private func filteredInput(_ value: String) -> String {
        var result = ""
        var hasDecimalSeparator = false
        var fractionalDigitCount = 0

        for character in value {
            if character.isNumber {
                if hasDecimalSeparator {
                    guard allowsDecimalInput, fractionalDigitCount < 1 else { continue }
                    fractionalDigitCount += 1
                }
                result.append(character)
            } else if character == ".", allowsDecimalInput, !hasDecimalSeparator, !result.isEmpty {
                hasDecimalSeparator = true
                result.append(character)
            }
        }

        return result
    }

    private func isPossibleRangePrefix(_ value: String) -> Bool {
        let integerPrefix = value.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: true).first.map(String.init) ?? value
        guard !integerPrefix.isEmpty else { return false }
        let lower = Int(inputRange.lowerBound.rounded(.up))
        let upper = Int(inputRange.upperBound.rounded(.down))
        return (lower...upper).contains(where: { String($0).hasPrefix(integerPrefix) })
    }

    private func formattedBoundary(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(value)) : String(value)
    }
}
