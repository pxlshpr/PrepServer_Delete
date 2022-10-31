import Fluent

struct CreateFoodItem: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("food_items")
            .id()
            .field("user_food_id", .uuid, .references(UserFood.schema, .id))
            .field("preset_food_id", .uuid, .references(PresetFood.schema, .id))
            .field("parent_user_food_id", .uuid, .references(UserFood.schema, .id))
            .field("meal_id", .uuid, .references(Meal.schema, .id))
            .field("created_at", .double)
            .field("updated_at", .double)
            .field("deleted_at", .double)

            .field("amount", .json, .required)
            .field("sort_position", .int16, .required)
            .field("marked_as_eaten_at", .double)

            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("food_items").delete()
    }
}
