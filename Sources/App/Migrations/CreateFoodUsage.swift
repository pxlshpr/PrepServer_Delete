import Fluent

struct CreateFoodUsage: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("food_usages")
            .id()
            .field("user_id", .uuid, .references(User.schema, .id))
            .field("user_food_id", .uuid, .references(UserFood.schema, .id))
            .field("preset_food_id", .uuid, .references(PresetFood.schema, .id))
            .field("created_at", .double, .required)
            .field("updated_at", .double, .required)

            .field("number_of_times_consumed", .int32)

            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("food_usages").delete()
    }
}
