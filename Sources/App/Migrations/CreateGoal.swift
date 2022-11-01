import Fluent

struct CreateGoal: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("goals")
            .id()
            .field("user_id", .uuid, .references(User.schema, .id))
            .field("created_at", .double, .required)
            .field("updated_at", .double, .required)
            .field("deleted_at", .double)

            .field("name", .string, .required)
            .field("is_for_meal", .bool, .required)
            .field("energy", .json)
            .field("macros", .array(of: .json))
            .field("micros", .array(of: .json))

            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("goals").delete()
    }
}
