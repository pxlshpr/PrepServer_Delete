import Fluent
import Vapor
import PrepDataTypes

final class EnergyExpenditures: Model, Content {
    static let schema = "energy_expenditures"
    
    @ID(key: .id) var id: UUID?
    @Parent(key: "user_id") var user: User
    @Parent(key: "day_id") var day: Day
    @Timestamp(key: "created_at", on: .create, format: .unix) var createdAt: Date?
    @Timestamp(key: "updated_at", on: .create, format: .unix) var updatedAt: Date?
    @Timestamp(key: "deleted_at", on: .create, format: .unix) var deletedAt: Date?

    @Field(key: "name") var name: String
    @Field(key: "type") var type: EnergyExpenditureType
    @Field(key: "energy_burned") var energyBurned: Double
    @OptionalField(key: "started_at") var startedAt: Date?
    @OptionalField(key: "ended_at") var endedAt: Date?
    @OptionalField(key: "duration") var duration: Int32?
    @OptionalField(key: "health_kit_workout") var healthKitWorkout: HealthKitWorkout?

    init() { }
}
