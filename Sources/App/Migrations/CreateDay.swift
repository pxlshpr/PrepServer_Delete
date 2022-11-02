import Fluent

struct CreateDay: AsyncMigration {
    
    func prepare(on database: Database) async throws {
        
        try await database.schema("days")
            .field("id", .string)
            .field("user_id", .uuid, .references(User.schema, .id), .required)
            .field("goal_id", .uuid, .references(Goal.schema, .id))
            .field("created_at", .double, .required)
            .field("updated_at", .double, .required)

            .field("calendar_day_string", .string, .required)
            .field("add_energy_expenditures_to_goal", .bool, .required)
            .field("goal_bonus_energy_split", .int16)
            .field("goal_bonus_energy_split_ratio", .int16)

            .unique(on: "id")
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("days").delete()
    }
}
