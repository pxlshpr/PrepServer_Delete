import Fluent

struct CreatePresetFood: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("preset_foods")
            .id()
            .field("created_at", .double)
            .field("updated_at", .double)
            .field("deleted_at", .double)

            .field("name", .string, .required)
            .field("emoji", .string, .required)
            .field("amount", .json, .required)
            .field("nutrients", .json, .required)
            .field("sizes", .array(of: .json), .required)
            .field("number_of_uses", .int32, .required)
            .field("dataset", .int16, .required)

            .field("serving", .json)
            .field("detail", .string)
            .field("brand", .string)
            .field("density", .json)
            .field("dataset_food_id", .string)

            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("preset_foods").delete()
    }
}
