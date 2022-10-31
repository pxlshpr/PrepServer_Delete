import Fluent
import Vapor
import PrepDataTypes

final class Goal: Model, Content {
    static let schema = "goals"
    
    @ID(key: .id) var id: UUID?
    @OptionalParent(key: "user_id") var user: User?
    @Timestamp(key: "created_at", on: .create, format: .unix) var createdAt: Date?
    @Timestamp(key: "updated_at", on: .create, format: .unix) var updatedAt: Date?
    @Timestamp(key: "deleted_at", on: .create, format: .unix) var deletedAt: Date?

    @Field(key: "name") var name: String
    @Field(key: "is_for_meal") var isForMeal: Bool
    @OptionalField(key: "energy") var energy: GoalEnergy?
    @OptionalField(key: "macros") var macros: [GoalMacro]?
    @OptionalField(key: "micros") var micros: [GoalMicro]?

    init() { }

    init(id: UUID? = nil) {
        self.id = id
    }
}
