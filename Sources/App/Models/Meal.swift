import Fluent
import Vapor

final class Meal: Model, Content {
    static let schema = "meals"
    
    @ID(key: .id) var id: UUID?
    @Parent(key: "day_id") var day: Day
    @Timestamp(key: "created_at", on: .create, format: .unix) var createdAt: Date?
    @Timestamp(key: "updated_at", on: .create, format: .unix) var updatedAt: Date?
    @Timestamp(key: "deleted_at", on: .create, format: .unix) var deletedAt: Date?

    @Field(key: "name") var name: String
    @Field(key: "time") var time: Date
    @OptionalField(key: "marked_as_eaten_at") var markedAsEatenAt: Date?

    @Children(for: \.$meal) var foodItems: [FoodItem]

    init() { }
}
