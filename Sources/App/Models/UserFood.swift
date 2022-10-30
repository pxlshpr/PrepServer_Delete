import Fluent
import Vapor
import PrepDataTypes

final class UserFood: Model, Content {
    static let schema = "user_foods"
    
    @ID(key: .id) var id: UUID?
    
    @Field(key: "name") var name: String
    @Field(key: "emoji") var emoji: String
    @OptionalField(key: "detail") var detail: String?
    @OptionalField(key: "brand") var brand: String?

    @Field(key: "amount") var amount: FoodValue
    @Field(key: "serving") var serving: FoodValue?
    @Field(key: "nutrients") var nutrients: FoodNutrients
    @Field(key: "sizes") var sizes: [FoodSize]
    @OptionalField(key: "density") var density: FoodDensity?
   
    @OptionalField(key: "link_url") var linkUrl: String?
    @OptionalField(key: "prefilled_url") var prefilledUrl: String?
    @OptionalField(key: "image_ids") var imageIds: [UUID]?

    @Field(key: "status") var status: UserFoodPublishStatus
    @OptionalParent(key: "spawned_user_food_id") var spawnedUserFood: UserFood?
    @OptionalParent(key: "spawned_database_food_id") var spawnedDatabaseFood: DatabaseFood?
    @Field(key: "changes") var changes: [UserFoodChange]
    @Field(key: "use_count_others") var numberOfUsesByOthers: Int32
    @Field(key: "use_count_owner") var numberOfUsesByOwner: Int32

    @Timestamp(key: "created_at", on: .create, format: .unix) var createdAt: Date?
    @Timestamp(key: "updated_at", on: .update, format: .unix) var updatedAt: Date?
    @Timestamp(key: "deleted_at", on: .delete, format: .unix) var deletedAt: Date?
    @OptionalField(key: "deleted_for_owner_at") var deletedForOwnerAt: Double?

    @Parent(key: "user_id") var user: User
    @Children(for: \.$userFood) var barcodes: [Barcode]
    
    init() { }

    init(_ form: UserFoodCreateForm, for db: Database) async throws {
        
        do {
            let _ = try form.validate()
        } catch let formError as UserFoodDataError {
            throw UserFoodCreateError.formError(formError)
        }
        
        let spawnedUserFood: UserFood?
        if let userFoodId = form.info.spawnedUserFoodId {
            guard let userFood = try await UserFood.find(userFoodId, on: db) else {
                throw UserFoodDataError.nonExistentSpawnedUserFood
            }
            spawnedUserFood = userFood
        } else {
            spawnedUserFood = nil
        }

        let spawnedDatabaseFood: DatabaseFood?
        if let databaseFoodId = form.info.spawnedDatabaseFoodId {
            guard let databaseFood = try await DatabaseFood.find(databaseFoodId, on: db) else {
                throw UserFoodDataError.nonExistentSpawnedDatabaseFood
            }
            spawnedDatabaseFood = databaseFood
        } else {
            spawnedDatabaseFood = nil
        }
        
        guard !(spawnedUserFood != nil && spawnedDatabaseFood != nil) else {
            throw UserFoodDataError.bothSpawnedUserAndDatabaseFoodsWereProvided
        }

        let user = try await UserController.createOrFetchUser(cloudKitId: form.info.cloudKitId, in: db)
        guard let userId = user.id else {
            throw UserCreateError.unableToCreateOrFetchUserForCloudKitId
        }
        
        /// **Deprecated**
//        /// Make sure we don't have any repeating barcodes
//        /// Validate each barcode
//        for barcode in form.info.barcodes {
//            /// Validate it first
//            try barcode.validate()
//        }
        
        //MARK: Now we can create the UserFood
        self.id = form.id
        self.name = form.name
        self.emoji = form.emoji
        self.detail = form.detail
        self.brand = form.brand
        self.amount = form.info.amount
        self.serving = form.info.serving
        self.nutrients = form.info.nutrients
        self.sizes = form.info.sizes
        self.density = form.info.density
        self.linkUrl = form.info.linkUrl
        self.prefilledUrl = form.info.prefilledUrl
        self.imageIds = form.info.imageIds
        self.status = form.publishStatus
        
        self.$user.id = userId
        
        self.changes = []
        self.numberOfUsesByOwner = 0
        self.numberOfUsesByOthers = 0
        
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
