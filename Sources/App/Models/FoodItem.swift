import Fluent
import Vapor
import PrepDataTypes

final class FoodItem: Model, Content {
    static let schema = "food_items"
    
    @ID(key: .id) var id: UUID?
    @OptionalParent(key: "user_food_id") var userFood: UserFood?
    @OptionalParent(key: "preset_food_id") var presetFood: PresetFood?
    @OptionalParent(key: "parent_user_food_id") var parentUserFood: UserFood?
    @OptionalParent(key: "meal_id") var meal: Meal?
    @Field(key: "created_at") var createdAt: Double
    @Field(key: "updated_at") var updatedAt: Double
    @OptionalField(key: "deleted_at") var deletedAt: Double?

    @Field(key: "amount") var amount: FoodValue
    @Field(key: "sort_position") var sortPosition: Int16
    @OptionalField(key: "marked_as_eaten_at") var markedAsEatenAt: Double?

    init() { }
}
