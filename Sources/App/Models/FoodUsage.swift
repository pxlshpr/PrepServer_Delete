import Fluent
import Vapor

final class FoodUsage: Model, Content {
    static let schema = "food_usages"
    
    @ID(key: .id) var id: UUID?
    @Parent(key: "user_id") var user: User
    @OptionalParent(key: "user_food_id") var userFood: UserFood?
    @OptionalParent(key: "preset_food_id") var presetFood: PresetFood?
    @Timestamp(key: "created_at", on: .create, format: .unix) var createdAt: Date?
    @Timestamp(key: "updated_at", on: .create, format: .unix) var updatedAt: Date?

    @Field(key: "number_of_times_consumed") var numberOfTimesConsumed: Int32

    init() { }
}
