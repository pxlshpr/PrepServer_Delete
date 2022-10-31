import Fluent

struct CreateUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .id()
            .field("cloud_kit_id", .string)
            .field("created_at", .double)
            .field("updated_at", .double)

            .field("preferred_energy_unit", .int16, .required)
            .field("prefers_metric_units", .bool, .required)
            .field("explicit_volume_units", .json, .required)
            .field("body_measurements", .json)
        
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("users").delete()
    }
}
