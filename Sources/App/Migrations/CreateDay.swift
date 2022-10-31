import Fluent

struct CreateDay: AsyncMigration {
    
    func prepare(on database: Database) async throws {
        
        try await database.schema("days")
            .id()
            .field("user_id", .uuid, .references(User.schema, .id), .required)
            .field("goal_id", .uuid, .references(Goal.schema, .id))
            .field("created_at", .double)
            .field("updated_at", .double)

            .field("date", .double, .required)
            .field("add_energy_expenditures_to_goal", .bool, .required)
            .field("goal_bonus_energy_split", .int16)
            .field("goal_bonus_energy_split_ratio", .int16)

            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("days").delete()
    }
}
