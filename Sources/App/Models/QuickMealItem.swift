import Fluent
import Vapor
import PrepDataTypes

final class QuickMealItem: Model, Content {
    static let schema = "quick_meal_items"
    
    @ID(key: .id) var id: UUID?
    @Parent(key: "meal_id") var meal: Meal
    @Timestamp(key: "created_at", on: .create, format: .unix) var createdAt: Date?
    @Timestamp(key: "updated_at", on: .create, format: .unix) var updatedAt: Date?
    @Timestamp(key: "deleted_at", on: .create, format: .unix) var deletedAt: Date?

    @Field(key: "name") var name: String
    @OptionalField(key: "nutrients") var nutrients: QuickMealNutrients?
    @OptionalField(key: "image_ids") var imageIds: [UUID]?

    init() { }
}

