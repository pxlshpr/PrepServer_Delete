import Fluent
import Vapor
import PrepDataTypes

final class User: Model, Content {
    static let schema = "users"
    
    @ID(key: .id) var id: UUID?
    
    @Field(key: "name") var name: String
    
    @Children(for: \.$user) var foods: [UserFood]

    init() { }

    init(_ form: UserCreateForm) {
        self.id = UUID()
        self.name = form.name
    }
}
