import Fluent

struct CreateTokenRedemption: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("token_redemptions")
            .id()
            .field("user_id", .uuid, .references(User.schema, .id), .required)
            .field("created_at", .double, .required)
            .field("deleted_at", .double)

            .field("tokens_redeemed", .int32, .required)
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("token_redemptions").delete()
    }
}
