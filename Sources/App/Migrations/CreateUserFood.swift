import Fluent

struct CreateUserFood: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("user_foods")
            .id()
            .field("user_id", .uuid, .references(User.schema, .id), .required)
            .field("spawned_user_food_id", .uuid, .references(UserFood.schema, .id))
            .field("spawned_preset_food_id", .uuid, .references(PresetFood.schema, .id))
            .field("created_at", .double, .required)
            .field("updated_at", .double, .required)
            .field("deleted_at", .double)
            .field("deleted_for_owner_at", .double)

            .field("food_type", .int16, .required)
            .field("name", .string, .required)
            .field("emoji", .string, .required)
            .field("amount", .json, .required)
            .field("nutrients", .json, .required)
            .field("sizes", .array(of: .json), .required)
            .field("publish_status", .int16, .required)
            .field("number_of_times_consumed", .int32, .required)
            .field("changes", .array(of: .json), .required)

            .field("serving", .json)
            .field("detail", .string)
            .field("brand", .string)
            .field("density", .json)
            .field("link_url", .string)
            .field("prefilled_url", .string)
            .field("image_ids", .array(of: .uuid))

            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("user_foods").delete()
    }
}
