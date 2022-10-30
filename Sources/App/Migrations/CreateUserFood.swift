import Fluent

struct CreateUserFood: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("user_foods")
            .id()
            .field("name", .string, .required)
            .field("emoji", .string, .required)
            .field("detail", .string)
            .field("brand", .string)

            .field("amount", .json, .required)
            .field("serving", .json)
            .field("nutrients", .json, .required)
            .field("sizes", .array(of: .json), .required)
            .field("density", .json)

            .field("link_url", .string)
            .field("prefilled_url", .string)
            .field("image_ids", .array(of: .uuid))
        
            .field("status", .int16, .required)
            .field("changes", .array(of: .json), .required)
            .field("use_count_others", .int32, .required)
            .field("use_count_owner", .int32, .required)

            .field("created_at", .double)
            .field("updated_at", .double)
            .field("deleted_at", .double)
            .field("deleted_for_owner_at", .double)

            .field("spawned_user_food_id", .uuid, .references(UserFood.schema, .id))
            .field("spawned_database_food_id", .uuid, .references(DatabaseFood.schema, .id))
            .field("user_id", .uuid, .references(User.schema, .id), .required)

            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("user_foods").delete()
    }
}
