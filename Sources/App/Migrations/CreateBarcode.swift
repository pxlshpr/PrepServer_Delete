import Fluent

struct CreateBarcode: AsyncMigration {
    
    func prepare(on database: Database) async throws {
        
        try await database.schema("barcodes")
            .id()
            .field("payload", .string, .required)
            .field("symbology", .int16, .required)
            .field("user_food_id", .uuid, .references(UserFood.schema, .id))
            .field("database_food_id", .uuid, .references(DatabaseFood.schema, .id))
            .field("created_at", .double)

            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("barcodes").delete()
    }
}
