import Fluent

struct CreateBarcode: AsyncMigration {
    
    func prepare(on database: Database) async throws {
        
        try await database.schema("barcodes")
            .field("payload", .string)
            .field("symbology", .int16, .required)
            .field("user_food_id", .uuid, .references(UserFood.schema, .id))
            .field("database_food_id", .uuid, .references(DatabaseFood.schema, .id))

            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("barcodes").delete()
    }
}
