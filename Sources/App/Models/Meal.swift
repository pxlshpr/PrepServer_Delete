import Fluent
import Vapor
import PrepDataTypes

final class Meal: Model, Content {
    static let schema = "meals"
    
    @ID(key: .id) var id: UUID?
    @Parent(key: "day_id") var day: Day
    @Field(key: "created_at") var createdAt: Double
    @Field(key: "updated_at") var updatedAt: Double
    @OptionalField(key: "deleted_at") var deletedAt: Double?

    @Field(key: "name") var name: String
    @Field(key: "time") var time: Double
    @OptionalField(key: "marked_as_eaten_at") var markedAsEatenAt: Double?

    @Children(for: \.$meal) var foodItems: [FoodItem]

    init() { }
    
    init(deviceMeal: PrepDataTypes.Meal, dayId: Day.IDValue) {
        self.id = deviceMeal.id
        self.$day.id = dayId
        
        print("Saving meal \(deviceMeal.name) with \(deviceMeal.updatedAt)")
        self.createdAt = deviceMeal.updatedAt
        self.updatedAt = deviceMeal.updatedAt
        self.deletedAt = nil
       
        self.name = deviceMeal.name
        self.time = deviceMeal.time
        self.markedAsEatenAt = deviceMeal.markedAsEatenAt
    }
}
