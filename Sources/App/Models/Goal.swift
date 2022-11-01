import Fluent
import Vapor
import PrepDataTypes

final class Goal: Model, Content {
    static let schema = "goals"
    
    @ID(key: .id) var id: UUID?
    @OptionalParent(key: "user_id") var user: User?
    @Field(key: "created_at") var createdAt: Double
    @Field(key: "updated_at") var updatedAt: Double
    @OptionalField(key: "deleted_at") var deletedAt: Double?

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
