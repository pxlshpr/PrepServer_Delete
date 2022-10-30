import Fluent
import Vapor
import PrepDataTypes

final class Barcode: Model, Content {
    static let schema = "barcodes"
    
    @ID(key: .id) var id: UUID?
    
    @Field(key: "payload") var payload: String
    @Field(key: "symbology") var symbology: BarcodeSymbology
    
    @OptionalParent(key: "user_food_id") var userFood: UserFood?
    @OptionalParent(key: "database_food_id") var databaseFood: DatabaseFood?

    @Timestamp(key: "created_at", on: .create, format: .unix) var createdAt: Date?

    init() { }
    
    init(payload: String, symbology: BarcodeSymbology, userFoodId: UserFood.IDValue?, databaseFoodId: DatabaseFood.IDValue?) {
        self.id = UUID()
        self.payload = payload
        self.symbology = symbology
        self.$userFood.id = userFoodId
        self.$databaseFood.id = databaseFoodId
        self.createdAt = Date()
    }
    
    init(barcode: FoodBarcode, userFoodId: UserFood.IDValue? = nil, databaseFoodId: DatabaseFood.IDValue? = nil) {
        self.id = UUID()
        self.payload = barcode.payload
        self.symbology = barcode.symbology
        self.$userFood.id = userFoodId
        self.$databaseFood.id = databaseFoodId
        self.createdAt = Date()
    }
}
