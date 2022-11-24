import Fluent

struct CreateDay: AsyncMigration {
    
    func prepare(on database: Database) async throws {
        
        try await database.schema("days")
            .field("id", .string)
            .field("user_id", .uuid, .references(User.schema, .id), .required)
            .field("goal_set_id", .uuid, .references(GoalSet.schema, .id))
            .field("created_at", .double, .required)
            .field("updated_at", .double, .required)

            .field("calendar_day_string", .string, .required)
            .field("body_profile", .json)

            .unique(on: "id")
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("days").delete()
    }
}
