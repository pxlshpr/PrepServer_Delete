import Fluent
import Vapor
import PrepDataTypes

final class TokenAward: Model, Content {
    static let schema = "token_awards"
    
    @ID(key: .id) var id: UUID?
    @Parent(key: "user_id") var user: User
    @Parent(key: "user_food_id") var userFood: UserFood
    @OptionalParent(key: "other_user_id") var otherUser: User?
    @Field(key: "created_at") var createdAt: Double
    @OptionalField(key: "deleted_at") var deletedAt: Double?

    @Field(key: "award_type") var awardType: TokenAwardType
    @Field(key: "tokens_awarded") var tokensAwarded: Int32

    init() { }

    init(id: UUID? = nil) {
        self.id = id
    }
}
