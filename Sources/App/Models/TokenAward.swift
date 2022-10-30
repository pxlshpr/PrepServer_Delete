import Fluent
import Vapor
import PrepDataTypes

final class TokenAward: Model, Content {
    static let schema = "token_awards"
    
    @ID(key: .id) var id: UUID?
    
    @Field(key: "tokens_awarded") var tokensAwarded: Int32
    @Parent(key: "user_id") var user: User
    @Parent(key: "user_food_id") var food: UserFood
    @OptionalParent(key: "other_user_id") var otherUser: User?
    @Timestamp(key: "created_at", on: .create, format: .unix) var createdAt: Date?

    init() { }

    init(id: UUID? = nil) {
        self.id = id
    }
}
