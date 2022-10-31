import Fluent

struct CreateTokenAward: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("token_awards")
            .id()
            .field("user_id", .uuid, .references(User.schema, .id), .required)
            .field("user_food_id", .uuid, .references(UserFood.schema, .id), .required)
            .field("other_user_id", .uuid, .references(User.schema, .id))
            .field("created_at", .double)
        
            .field("award_type", .int16, .required)
            .field("tokens_awarded", .int32, .required)
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("token_awards").delete()
    }
}
