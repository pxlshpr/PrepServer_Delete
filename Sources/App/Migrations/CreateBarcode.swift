import Fluent

struct CreateBarcode: AsyncMigration {
    
    func prepare(on database: Database) async throws {
        
        try await database.schema("barcodes")
            .id()
            .field("user_food_id", .uuid, .references(UserFood.schema, .id))
            .field("preset_food_id", .uuid, .references(PresetFood.schema, .id))
            .field("created_at", .double)
        
            .field("payload", .string, .required)
            .field("symbology", .int16, .required)

            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("barcodes").delete()
    }
}
