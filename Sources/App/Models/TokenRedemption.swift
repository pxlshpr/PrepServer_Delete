import Fluent
import Vapor
import PrepDataTypes

final class TokenRedemption: Model, Content {
    static let schema = "token_redemptions"
    
    @ID(key: .id) var id: UUID?
    @Parent(key: "user_id") var user: User
    @Timestamp(key: "created_at", on: .create, format: .unix) var createdAt: Date?

    @Field(key: "tokens_redeemed") var tokensRedeemed: Int32

    init() { }

    init(id: UUID? = nil) {
        self.id = id
    }
}
