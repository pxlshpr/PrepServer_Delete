import Fluent
import Vapor
import PrepDataTypes

final class PresetFood: Model, Content {
    static let schema = "preset_foods"
    
    @ID(key: .id) var id: UUID?
    @Timestamp(key: "created_at", on: .create, format: .unix) var createdAt: Date?
    @Timestamp(key: "updated_at", on: .update, format: .unix) var updatedAt: Date?
    @Timestamp(key: "deleted_at", on: .delete, format: .unix) var deletedAt: Date?

    @Field(key: "name") var name: String
    @Field(key: "emoji") var emoji: String
    @Field(key: "amount") var amount: FoodValue
    @Field(key: "nutrients") var nutrients: FoodNutrients
    @Field(key: "sizes") var sizes: [FoodSize]
    @Field(key: "number_of_times_consumed") var numberOfTimesConsumed: Int32
    @Field(key: "dataset") var dataset: FoodDataset

    @OptionalField(key: "serving") var serving: FoodValue?
    @OptionalField(key: "detail") var detail: String?
    @OptionalField(key: "brand") var brand: String?
    @OptionalField(key: "density") var density: FoodDensity?
    @OptionalField(key: "dataset_food_id") var datasetFoodId: String?
    
    @Children(for: \.$presetFood) var barcodes: [Barcode]
    
    init() { }

    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}
