import Fluent

struct CreateQuickMealItem: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("quick_meal_items")
            .id()
            .field("meal_id", .uuid, .references(Meal.schema, .id), .required)
            .field("created_at", .double, .required)
            .field("updated_at", .double, .required)
            .field("deleted_at", .double)

            .field("name", .string, .required)
            .field("nutrients", .json)
            .field("image_ids", .array(of: .uuid))

            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("quick_meal_items").delete()
    }
}
