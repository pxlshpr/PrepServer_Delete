import Fluent
import Vapor
import PrepDataTypes

final class GoalSet: Model, Content {
    static let schema = "goal_sets"
    
    @ID(key: .id) var id: UUID?
    @OptionalParent(key: "user_id") var user: User?
    @Field(key: "created_at") var createdAt: Double
    @Field(key: "updated_at") var updatedAt: Double
    @OptionalField(key: "deleted_at") var deletedAt: Double?

    @Field(key: "name") var name: String
    @Field(key: "emoji") var emoji: String
    @Field(key: "is_for_meal") var isForMeal: Bool
    @Field(key: "goals") var goals: [ServerGoal]

    init() { }

    init(id: UUID? = nil) {
        self.id = id
    }
}

struct ServerGoal: Codable {
    let type: GoalTypeValue
    let lowerBound: Double?
    let upperBound: Double?
}
