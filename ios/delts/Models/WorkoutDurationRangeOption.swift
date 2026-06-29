import Foundation

/// Preset workout-duration ranges shown in the profile preferences picker.
struct WorkoutDurationRangeOption: Hashable, Identifiable {
    let lowerBound: Int
    let upperBound: Int?

    var id: String {
        if let upperBound {
            return "\(lowerBound)-\(upperBound)"
        }
        return "\(lowerBound)-plus"
    }

    var title: String {
        if let upperBound {
            if lowerBound < 60, upperBound < 60 {
                return String(localized: "\(lowerBound)-\(upperBound) min")
            }
            if lowerBound >= 60, upperBound >= 60 {
                return String(localized: "\(hourText(for: lowerBound))-\(hourText(for: upperBound)) hr")
            }
            return String(localized: "\(durationText(for: lowerBound))-\(durationText(for: upperBound))")
        }
        return String(localized: "\(durationText(for: lowerBound))+")
    }

    var promptText: String {
        if let upperBound {
            return "\(durationText(for: lowerBound)) to \(durationText(for: upperBound))"
        }
        return "\(durationText(for: lowerBound)) or longer"
    }

    var targetMinutes: Int { upperBound ?? 150 }

    static let options: [WorkoutDurationRangeOption] = [
        WorkoutDurationRangeOption(lowerBound: 20, upperBound: 30),
        WorkoutDurationRangeOption(lowerBound: 30, upperBound: 45),
        WorkoutDurationRangeOption(lowerBound: 45, upperBound: 60),
        WorkoutDurationRangeOption(lowerBound: 60, upperBound: 90),
        WorkoutDurationRangeOption(lowerBound: 90, upperBound: 120),
        WorkoutDurationRangeOption(lowerBound: 120, upperBound: nil)
    ]

    static func matching(minutes: Int) -> WorkoutDurationRangeOption {
        options.first { option in
            if let upperBound = option.upperBound {
                return option.lowerBound <= minutes && minutes <= upperBound
            }
            return minutes >= option.lowerBound
        }
            ?? options.min { abs($0.targetMinutes - minutes) < abs($1.targetMinutes - minutes) }
            ?? options[2]
    }

    private func durationText(for minutes: Int) -> String {
        switch minutes {
        case 120:
            return String(localized: "2 hr")
        case let value where value > 60 && value % 60 == 30:
            return "\(Double(value) / 60.0) hr"
        case let value where value >= 60 && value % 60 == 0:
            return String(localized: "\(value / 60) hr")
        default:
            return String(localized: "\(minutes) min")
        }
    }

    private func hourText(for minutes: Int) -> String {
        let hours = Double(minutes) / 60.0
        if hours.rounded() == hours {
            return "\(Int(hours))"
        }
        return hours.formatted(.number.precision(.fractionLength(1)))
    }
}
