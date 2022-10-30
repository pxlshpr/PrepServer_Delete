import Fluent
import Vapor
import PrepDataTypes

final class User: Model, Content {
    static let schema = "users"
    
    @ID(key: .id) var id: UUID?
    
    @OptionalField(key: "cloud_kit_id") var cloudKitId: String?
    
    @Timestamp(key: "created_at", on: .create, format: .unix) var createdAt: Date?
    @Timestamp(key: "updated_at", on: .update, format: .unix) var updatedAt: Date?

    @Children(for: \.$user) var foods: [UserFood]

    init() { }
    
    init(cloudKitId: String) {
        self.id = UUID()
        self.cloudKitId = cloudKitId
        
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
