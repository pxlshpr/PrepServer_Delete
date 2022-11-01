import Fluent
import Vapor
import PrepDataTypes

final class TokenRedemption: Model, Content {
    static let schema = "token_redemptions"
    
    @ID(key: .id) var id: UUID?
    @Parent(key: "user_id") var user: User
    @Field(key: "created_at") var createdAt: Double
    @OptionalField(key: "deleted_at") var deletedAt: Double?

    @Field(key: "tokens_redeemed") var tokensRedeemed: Int32

    init() { }

    init(id: UUID? = nil) {
        self.id = id
    }
}
