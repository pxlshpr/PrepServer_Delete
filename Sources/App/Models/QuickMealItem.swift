import Fluent
import Vapor
import PrepDataTypes

final class QuickMealItem: Model, Content {
    static let schema = "quick_meal_items"
    
    @ID(key: .id) var id: UUID?
    @Parent(key: "meal_id") var meal: Meal
    @Field(key: "created_at") var createdAt: Double
    @Field(key: "updated_at") var updatedAt: Double
    @OptionalField(key: "deleted_at") var deletedAt: Double?

    @Field(key: "name") var name: String
    @OptionalField(key: "nutrients") var nutrients: QuickMealNutrients?
    @OptionalField(key: "image_ids") var imageIds: [UUID]?

    init() { }
}

