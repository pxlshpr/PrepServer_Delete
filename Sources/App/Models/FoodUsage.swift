import Fluent
import Vapor

final class FoodUsage: Model, Content {
    static let schema = "food_usages"
    
    @ID(key: .id) var id: UUID?
    @Parent(key: "user_id") var user: User
    @OptionalParent(key: "user_food_id") var userFood: UserFood?
    @OptionalParent(key: "preset_food_id") var presetFood: PresetFood?
    @Field(key: "created_at") var createdAt: Double
    @Field(key: "updated_at") var updatedAt: Double

    @Field(key: "number_of_times_consumed") var numberOfTimesConsumed: Int32

    init() { }
}
