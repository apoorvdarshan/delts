import Foundation
import SwiftData

@Model
final class Exercise: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var targetMuscleRaw: String
    var equipmentRaw: String
    var formTip: String
    var difficulty: String

    init(
        id: UUID = UUID(),
        name: String,
        targetMuscle: MuscleGroup,
        equipment: Equipment,
        formTip: String,
        difficulty: String
    ) {
        self.id = id
        self.name = name
        self.targetMuscleRaw = targetMuscle.rawValue
        self.equipmentRaw = equipment.rawValue
        self.formTip = formTip
        self.difficulty = difficulty
    }

    var targetMuscle: MuscleGroup {
        MuscleGroup(rawValue: targetMuscleRaw) ?? .fullBody
    }

    var equipment: Equipment {
        Equipment(rawValue: equipmentRaw) ?? .bodyweight
    }
}

