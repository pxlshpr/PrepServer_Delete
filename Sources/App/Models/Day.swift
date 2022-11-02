import Fluent
import Vapor
import PrepDataTypes

final class Day: Model, Content {
    static let schema = "days"
    
    @ID(custom: "id", generatedBy: .user) var id: String?
    @Parent(key: "user_id") var user: User
    @OptionalParent(key: "goal_id") var goal: Goal?
    @Field(key: "created_at") var createdAt: Double
    @Field(key: "updated_at") var updatedAt: Double

    @Field(key: "calendar_day_string") var calendarDayString: String
    @Field(key: "add_energy_expenditures_to_goal") var addEnergyExpendituresToGoal: Bool
    @OptionalField(key: "goal_bonus_energy_split") var goalBonusEnergySplit: GoalBonusEnergySplit?
    @OptionalField(key: "goal_bonus_energy_split_ratio") var goalBonusEnergySplitRatio: GoalBonusEnergySplitRatio?

    @Children(for: \.$day) var meals: [Meal]
    @Children(for: \.$day) var energyExpenditures: [EnergyExpenditures]

    init() { }
    
    init(deviceDay: PrepDataTypes.Day, userId: User.IDValue, goalId: Goal.IDValue?) {
        self.id = deviceDay.id
        self.$user.id = userId
        self.$goal.id = goalId
        
        self.createdAt = deviceDay.updatedAt
        self.updatedAt = deviceDay.updatedAt
       
        self.calendarDayString = deviceDay.calendarDayString
        self.addEnergyExpendituresToGoal = deviceDay.addEnergyExpendituresToGoal
        self.goalBonusEnergySplit = deviceDay.goalBonusEnergySplit
        self.goalBonusEnergySplitRatio = deviceDay.goalBonusEnergySplitRatio
    }
}
