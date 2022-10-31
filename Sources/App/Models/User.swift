import Fluent
import Vapor
import PrepDataTypes

final class User: Model, Content {
    static let schema = "users"
    
    @ID(key: .id) var id: UUID?
    @OptionalField(key: "cloud_kit_id") var cloudKitId: String?
    @Timestamp(key: "created_at", on: .create, format: .unix) var createdAt: Date?
    @Timestamp(key: "updated_at", on: .update, format: .unix) var updatedAt: Date?

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
        
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

extension UserExplicitVolumeUnits {
    static var defaultUnits: UserExplicitVolumeUnits {
        UserExplicitVolumeUnits(
            cup: .cupMetric,
            teaspoon: .teaspoonMetric,
            tablespoon: .tablespoonMetric,
            fluidOunce: .fluidOunceUSNutritionLabeling,
            pint: .pintMetric,
            quart: .quartUSLiquid,
            gallon: .gallonUSLiquid
        )
    }
}

extension BodyMeasurements {
    static var empty: BodyMeasurements {
        BodyMeasurements(
            currentWeight: nil,
            currentHeight: nil,
            pastWeights: [],
            pastHeights: []
        )
    }
}
