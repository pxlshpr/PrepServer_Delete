import Fluent

struct CreateDatabaseFood: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("database_foods")
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

            .field("database", .int16)
            .field("database_food_id", .string)

            .field("created_at", .double)
            .field("updated_at", .double)
            .field("deleted_at", .double)

            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("database_foods").delete()
    }
}
