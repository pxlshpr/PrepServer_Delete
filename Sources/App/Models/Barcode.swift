import Fluent
import Vapor
import PrepDataTypes

final class Barcode: Model, Content {
    static let schema = "barcodes"
    
    @ID(custom: "payload", generatedBy: .user) var id: String?
    @Field(key: "symbology") var symbology: BarcodeSymbology
    
    @OptionalParent(key: "user_food_id") var userFood: UserFood?
    @OptionalParent(key: "database_food_id") var databaseFood: DatabaseFood?

    init() { }
    
    init(payload: String? = nil, symbology: BarcodeSymbology, userFoodId: UserFood.IDValue?, databaseFoodId: DatabaseFood.IDValue?) {
        self.id = payload
        self.symbology = symbology
        self.$userFood.id = userFoodId
        self.$databaseFood.id = databaseFoodId
    }
    
    init(barcode: FoodBarcode, userFoodId: UserFood.IDValue? = nil, databaseFoodId: DatabaseFood.IDValue? = nil) {
        self.id = barcode.payload
        self.symbology = barcode.symbology
        self.$userFood.id = userFoodId
        self.$databaseFood.id = databaseFoodId
    }
}
