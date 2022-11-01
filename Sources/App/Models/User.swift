import Fluent
import Vapor
import PrepDataTypes

final class User: Model, Content {
    static let schema = "users"
    
    @ID(key: .id) var id: UUID?
    @OptionalField(key: "cloud_kit_id") var cloudKitId: String?
    @Field(key: "created_at") var createdAt: Double
    @Field(key: "updated_at") var updatedAt: Double

    @Field(key: "preferred_energy_unit") var preferredEnergyUnit: EnergyUnit
    @Field(key: "prefers_metric_units") var prefersMetricUnit: Bool
    @Field(key: "explicit_volume_units") var explicitVolumeUnits: UserExplicitVolumeUnits
    @OptionalField(key: "body_measurements") var bodyMeasurements: BodyMeasurements?

    @Children(for: \.$user) var days: [Day]
    @Children(for: \.$user) var foodUsages: [FoodUsage]
    @Children(for: \.$user) var goals: [Goal]
    @Children(for: \.$user) var tokenAwards: [TokenAward]
    @Children(for: \.$user) var tokenRedemptions: [TokenRedemption]
    @Children(for: \.$user) var userFoods: [UserFood]

    init() { }
    
    init(
        cloudKitId: String,
        preferredEnergyUnit: EnergyUnit = .kcal,
        prefersMetricUnit: Bool = true,
        explicitVolumeUnits: UserExplicitVolumeUnits = UserExplicitVolumeUnits.defaultUnits,
        bodyMeasurements: BodyMeasurements = BodyMeasurements.empty
    ) {
        self.id = UUID()
        self.cloudKitId = cloudKitId
        
        self.preferredEnergyUnit = preferredEnergyUnit
        self.prefersMetricUnit = prefersMetricUnit
        self.explicitVolumeUnits = explicitVolumeUnits
        self.bodyMeasurements = bodyMeasurements
        
        self.createdAt = Date().timeIntervalSince1970
        self.updatedAt = Date().timeIntervalSince1970
    }
    
    init(deviceUser: PrepDataTypes.User) {
        self.id = deviceUser.id
        self.cloudKitId = deviceUser.cloudKitId
        
        self.preferredEnergyUnit = deviceUser.preferredEnergyUnit
        self.prefersMetricUnit = deviceUser.prefersMetricUnits
        self.explicitVolumeUnits = deviceUser.explicitVolumeUnits
        self.bodyMeasurements = deviceUser.bodyMeasurements
        
        self.createdAt = deviceUser.updatedAt
        self.updatedAt = deviceUser.updatedAt
    }
}

