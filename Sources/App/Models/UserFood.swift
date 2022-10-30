import Fluent
import Vapor
import PrepDataTypes

final class UserFood: Model, Content {
    static let schema = "user_foods"
    
    @ID(key: .id) var id: UUID?
    @Parent(key: "user_id") var user: User
    @OptionalParent(key: "spawned_user_food_id") var spawnedUserFood: UserFood?
    @OptionalParent(key: "spawned_database_food_id") var spawnedDatabaseFood: DatabaseFood?
    @Timestamp(key: "created_at", on: .create, format: .unix) var createdAt: Date?
    @Timestamp(key: "updated_at", on: .update, format: .unix) var updatedAt: Date?
    @Timestamp(key: "deleted_at", on: .delete, format: .unix) var deletedAt: Date?
    @OptionalField(key: "deleted_for_owner_at") var deletedForOwnerAt: Double?

    @Field(key: "food_type") var foodType: FoodType
    @Field(key: "name") var name: String
    @Field(key: "emoji") var emoji: String
    @Field(key: "amount") var amount: FoodValue
    @Field(key: "nutrients") var nutrients: FoodNutrients
    @Field(key: "sizes") var sizes: [FoodSize]
    @Field(key: "publish_status") var publishStatus: UserFoodPublishStatus
    @Field(key: "number_of_uses") var numberOfUses: Int32
    @Field(key: "changes") var changes: [UserFoodChange]
    @OptionalField(key: "serving") var serving: FoodValue?
    @OptionalField(key: "detail") var detail: String?
    @OptionalField(key: "brand") var brand: String?
    @OptionalField(key: "density") var density: FoodDensity?
    @OptionalField(key: "link_url") var linkUrl: String?
    @OptionalField(key: "prefilled_url") var prefilledUrl: String?
    @OptionalField(key: "image_ids") var imageIds: [UUID]?

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
        
        self.foodType = .rawFood
        
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
        self.publishStatus = form.publishStatus
        
        self.$user.id = userId
        
        self.changes = []
        self.numberOfUses = 0
        
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
