import Fluent
import Vapor
import PrepDataTypes

final class Barcode: Model, Content {
    static let schema = "barcodes"
    
    @ID(key: .id) var id: UUID?
    @OptionalParent(key: "user_food_id") var userFood: UserFood?
    @OptionalParent(key: "preset_food_id") var presetFood: PresetFood?
    @Timestamp(key: "created_at", on: .create, format: .unix) var createdAt: Date?
    @Timestamp(key: "deleted_at", on: .create, format: .unix) var deletedAt: Date?

    @Field(key: "payload") var payload: String
    @Field(key: "symbology") var symbology: BarcodeSymbology

    init() { }
    
    init(payload: String, symbology: BarcodeSymbology, userFoodId: UserFood.IDValue?, presetFoodId: PresetFood.IDValue?) {
        self.id = UUID()
        self.payload = payload
        self.symbology = symbology
        self.$userFood.id = userFoodId
        self.$presetFood.id = presetFoodId
        self.createdAt = Date()
    }
    
    init(barcode: FoodBarcode, userFoodId: UserFood.IDValue? = nil, presetFoodId: PresetFood.IDValue? = nil) {
        self.id = UUID()
        self.payload = barcode.payload
        self.symbology = barcode.symbology
        self.$userFood.id = userFoodId
        self.$presetFood.id = presetFoodId
        self.createdAt = Date()
    }
}
