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
    @Field(key: "type") var type: GoalSetType
    @Field(key: "goals") var goals: [Goal]

    init() { }

    init(id: UUID? = nil) {
        self.id = id
    }
    
    init(
        deviceGoalSet: PrepDataTypes.GoalSet,
        userId: User.IDValue
    ) {
        self.id = deviceGoalSet.id
        self.$user.id = userId
        
        let timestamp = Date().timeIntervalSince1970
        self.createdAt = timestamp
        self.updatedAt = timestamp
        
        self.name = deviceGoalSet.name
        self.emoji = deviceGoalSet.emoji
        self.type = deviceGoalSet.type
        self.goals = deviceGoalSet.goals
    }
}

extension GoalSet {
    func update(with deviceGoalSet: PrepDataTypes.GoalSet) throws {
        self.name = deviceGoalSet.name
        self.emoji = deviceGoalSet.emoji
        self.type = deviceGoalSet.type
        self.goals = deviceGoalSet.goals
        self.updatedAt = Date().timeIntervalSince1970
    }
    
    func softDelete() {
        let timestamp = Date().timeIntervalSince1970
        self.deletedAt = timestamp
        self.updatedAt = timestamp
    }
}

//MARK: - GoalSet → PrepDataTypes.GoalSet

extension PrepDataTypes.GoalSet {
    init?(from serverGoalSet: GoalSet) {
        guard let id = serverGoalSet.id else {
            return nil
        }
        self.init(
            id: id,
            type: serverGoalSet.type,
            name: serverGoalSet.name,
            emoji: serverGoalSet.emoji,
            goals: serverGoalSet.goals,
            syncStatus: .synced,
            updatedAt: serverGoalSet.updatedAt,
            deletedAt: serverGoalSet.deletedAt
        )
    }
}
