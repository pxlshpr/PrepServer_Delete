import Fluent
import Vapor
import PrepDataTypes

final class Day: Model, Content {
    static let schema = "days"
    
    @ID(custom: "id", generatedBy: .user) var id: String?
    @Parent(key: "user_id") var user: User
    @OptionalParent(key: "goal_set_id") var goalSet: GoalSet?
    @Field(key: "created_at") var createdAt: Double
    @Field(key: "updated_at") var updatedAt: Double

    @Field(key: "calendar_day_string") var calendarDayString: String
    @OptionalField(key: "body_profile") var bodyProfile: BodyProfile?

    @Children(for: \.$day) var meals: [Meal]

    init() { }
    
    init(
        deviceDay: PrepDataTypes.Day,
        userId: User.IDValue,
        goalSetId: GoalSet.IDValue?
    ) {
        self.id = deviceDay.id
        self.$user.id = userId
        self.$goalSet.id = goalSetId
        
//        self.createdAt = deviceDay.updatedAt
//        self.updatedAt = deviceDay.updatedAt
        let timestamp = Date().timeIntervalSince1970
        self.createdAt = timestamp
        self.updatedAt = timestamp

        self.calendarDayString = deviceDay.calendarDayString
        self.bodyProfile = deviceDay.bodyProfile
    }
}

extension Day {
    func update(with deviceDay: PrepDataTypes.Day, newGoalSetId: GoalSet.IDValue?) throws {
        self.$goalSet.id = newGoalSetId
        self.bodyProfile = deviceDay.bodyProfile
//        serverDay.updatedAt = deviceDay.updatedAt
        self.updatedAt = Date().timeIntervalSince1970
    }
}
