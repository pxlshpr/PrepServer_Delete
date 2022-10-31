import Fluent

struct CreateMeal: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("meals")
            .id()
            .field("day_id", .uuid, .references(Day.schema, .id), .required)
            .field("created_at", .double)
            .field("updated_at", .double)
            .field("deleted_at", .double)

            .field("name", .string, .required)
            .field("time", .double, .required)
            .field("marked_as_eaten_at", .double)

            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("meals").delete()
    }
}
