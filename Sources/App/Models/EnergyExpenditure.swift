import Fluent
import Vapor
import PrepDataTypes

final class EnergyExpenditures: Model, Content {
    static let schema = "energy_expenditures"
    
    @ID(key: .id) var id: UUID?
    @Parent(key: "user_id") var user: User
    @Parent(key: "day_id") var day: Day
    @Field(key: "created_at") var createdAt: Double
    @Field(key: "updated_at") var updatedAt: Double
    @OptionalField(key: "deleted_at") var deletedAt: Double?

    @Field(key: "name") var name: String
    @Field(key: "type") var type: EnergyExpenditureType
    @Field(key: "energy_burned") var energyBurned: Double
    @OptionalField(key: "started_at") var startedAt: Double?
    @OptionalField(key: "ended_at") var endedAt: Double?
    @OptionalField(key: "duration") var duration: Int32?
    @OptionalField(key: "health_kit_workout") var healthKitWorkout: HealthKitWorkout?

    init() { }
}
