import Fluent

struct CreateEnergyExpenditure: AsyncMigration {
    
    func prepare(on database: Database) async throws {
        
        try await database.schema("energy_expenditures")
            .id()
            .field("day_id", .uuid, .references(Day.schema, .id), .required)
            .field("created_at", .double, .required)
            .field("updated_at", .double, .required)
            .field("deleted_at", .double)

            .field("name", .string, .required)
            .field("type", .int16, .required)
            .field("energy_burned", .double, .required)
            .field("started_at", .double)
            .field("ended_at", .double)
            .field("duration", .int32)
            .field("health_kit_workout", .json)

            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("energy_expenditures").delete()
    }
}
