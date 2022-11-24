import Fluent
import Vapor
import PrepDataTypes

final class User: Model, Content {
    static let schema = "users"
    
    @ID(key: .id) var id: UUID?
    @OptionalField(key: "cloud_kit_id") var cloudKitId: String?
    @Field(key: "created_at") var createdAt: Double
    @Field(key: "updated_at") var updatedAt: Double

    @Field(key: "units") var units: UserUnits
    @OptionalField(key: "body_profile") var bodyProfile: BodyProfile?
    @OptionalField(key: "body_profile_updated_at") var bodyProfileUpdatedAt: Double?

    @Children(for: \.$user) var days: [Day]
    @Children(for: \.$user) var foodUsages: [FoodUsage]
    @Children(for: \.$user) var goalSets: [GoalSet]
    @Children(for: \.$user) var tokenAwards: [TokenAward]
    @Children(for: \.$user) var tokenRedemptions: [TokenRedemption]
    @Children(for: \.$user) var userFoods: [UserFood]

    init() { }
    
    init(
        cloudKitId: String,
        units: UserUnits = .standard,
        bodyProfile: BodyProfile? = nil,
        bodyProfileUpdatedAt: Double? = nil
    ) {
        self.id = UUID()
        self.cloudKitId = cloudKitId
        
        self.units = units
        self.bodyProfile = bodyProfile
        self.bodyProfileUpdatedAt = bodyProfileUpdatedAt
        
        self.createdAt = Date().timeIntervalSince1970
        self.updatedAt = Date().timeIntervalSince1970
    }
    
    init(deviceUser: PrepDataTypes.User) {
        self.id = deviceUser.id
        self.cloudKitId = deviceUser.cloudKitId
        
        self.units = deviceUser.units
        self.bodyProfile = deviceUser.bodyProfile
        self.bodyProfileUpdatedAt = deviceUser.bodyProfileUpdatedAt
        
        self.createdAt = deviceUser.updatedAt
        self.updatedAt = deviceUser.updatedAt
    }
}

