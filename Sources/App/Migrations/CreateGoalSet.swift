import Fluent

struct CreateGoalSet: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("goal_sets")
            .id()
            .field("user_id", .uuid, .references(User.schema, .id))
            .field("created_at", .double, .required)
            .field("updated_at", .double, .required)
            .field("deleted_at", .double)

            .field("name", .string, .required)
            .field("emoji", .string, .required)
            .field("type", .int16, .required)
            .field("goals", .array(of: .json), .required)

            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("goal_sets").delete()
    }
}
