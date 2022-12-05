import Fluent
import Vapor
import PrepDataTypes

final class Meal: Model, Content {
    static let schema = "meals"
    
    @ID(key: .id) var id: UUID?
    @Parent(key: "day_id") var day: Day
    @OptionalParent(key: "goal_set_id") var goalSet: GoalSet?
    @Field(key: "created_at") var createdAt: Double
    @Field(key: "updated_at") var updatedAt: Double
    @OptionalField(key: "deleted_at") var deletedAt: Double?

    @Field(key: "name") var name: String
    @Field(key: "time") var time: Double
    @OptionalField(key: "marked_as_eaten_at") var markedAsEatenAt: Double?
    @OptionalField(key: "goal_workout_minutes") var goalWorkoutMinutes: Int?

    @Children(for: \.$meal) var foodItems: [FoodItem]

    init() { }
    
    init(
        deviceMeal: PrepDataTypes.Meal,
        dayId: Day.IDValue,
        goalSetId: GoalSet.IDValue?
    ) {
        self.id = deviceMeal.id
        self.$day.id = dayId
        self.$goalSet.id = goalSetId
        
        let timestamp = Date().timeIntervalSince1970
        self.createdAt = timestamp
        self.updatedAt = timestamp
        self.deletedAt = nil
       
        self.name = deviceMeal.name
        self.time = deviceMeal.time
        self.markedAsEatenAt = deviceMeal.markedAsEatenAt
        self.goalWorkoutMinutes = deviceMeal.goalWorkoutMinutes
    }
}

extension Meal {
    func update(with deviceMeal: PrepDataTypes.Meal, newDayId: Day.IDValue?, newGoalSetId: GoalSet.IDValue?) throws {
        if let newDayId {
            self.$day.id = newDayId
        }
        if let newGoalSetId {
            self.$goalSet.id = newGoalSetId
        }
        self.name = deviceMeal.name
        self.time = deviceMeal.time
        if let markedAsEatenAt = deviceMeal.markedAsEatenAt {
            self.markedAsEatenAt = markedAsEatenAt
        } else {
            self.markedAsEatenAt = nil
        }
        
        self.updatedAt = Date().timeIntervalSince1970
    }
    
    func softDelete() {
        let timestamp = Date().timeIntervalSince1970
        self.deletedAt = timestamp
        self.updatedAt = timestamp
    }
}

//MARK: - Meal → PrepDataTypes.Meal

extension PrepDataTypes.Meal {
    init?(from serverMeal: Meal) {
        guard let id = serverMeal.id,
              let day = PrepDataTypes.Day(from: serverMeal.day)
        else {
            return nil
        }
        
        let goalSet: PrepDataTypes.GoalSet?
        if let serverGoalSet = serverMeal.goalSet,
           let deviceGoalSet = PrepDataTypes.GoalSet(from: serverGoalSet)
        {
            goalSet = deviceGoalSet
        } else {
            goalSet = nil
        }

        self.init(
            id: id,
            day: day,
            name: serverMeal.name,
            time: serverMeal.time,
            markedAsEatenAt: serverMeal.markedAsEatenAt,
            goalSet: goalSet,
            goalWorkoutMinutes: serverMeal.goalWorkoutMinutes,
            foodItems: [],
            syncStatus: .synced,
            updatedAt: serverMeal.updatedAt,
            deletedAt: serverMeal.deletedAt
        )
    }
}
