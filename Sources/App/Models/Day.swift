import Fluent
import Vapor
import PrepDataTypes

final class Day: Model, Content {
    static let schema = "days"
    
    @ID(key: .id) var id: UUID?
    @Parent(key: "user_id") var user: User
    @OptionalParent(key: "goal_id") var goal: Goal?
    @Timestamp(key: "created_at", on: .create, format: .unix) var createdAt: Date?
    @Timestamp(key: "updated_at", on: .create, format: .unix) var updatedAt: Date?

    @Field(key: "date") var date: Date
    @Field(key: "add_energy_expenditures_to_goal") var addEnergyExpendituresToGoal: Bool
    @OptionalField(key: "goal_bonus_energy_split") var goalBonusEnergySplit: GoalBonusEnergySplit?
    @OptionalField(key: "goal_bonus_energy_split_ratio") var goalBonusEnergySplitRatio: GoalBonusEnergySplitRatio?

    @Children(for: \.$day) var meals: [Meal]
    @Children(for: \.$day) var energyExpenditures: [EnergyExpenditures]

    init() { }
}
