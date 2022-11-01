import Fluent
import Vapor
import PrepDataTypes

final class UserFood: Model, Content {
    static let schema = "user_foods"
    
    @ID(key: .id) var id: UUID?
    @Parent(key: "user_id") var user: User
    @OptionalParent(key: "spawned_user_food_id") var spawnedUserFood: UserFood?
    @OptionalParent(key: "spawned_preset_food_id") var spawnedPresetFood: PresetFood?
    @Field(key: "created_at") var createdAt: Double
    @Field(key: "updated_at") var updatedAt: Double
    @OptionalField(key: "deleted_at") var deletedAt: Double?
    @OptionalField(key: "deleted_for_owner_at") var deletedForOwnerAt: Double?

    @Field(key: "food_type") var foodType: FoodType
    @Field(key: "name") var name: String
    @Field(key: "emoji") var emoji: String
    @Field(key: "amount") var amount: FoodValue
    @Field(key: "nutrients") var nutrients: FoodNutrients
    @Field(key: "sizes") var sizes: [FoodSize]
    @Field(key: "publish_status") var publishStatus: UserFoodPublishStatus
    @Field(key: "number_of_times_consumed") var numberOfTimesConsumed: Int32
    @Field(key: "changes") var changes: [UserFoodChange]
    @OptionalField(key: "serving") var serving: FoodValue?
    @OptionalField(key: "detail") var detail: String?
    @OptionalField(key: "brand") var brand: String?
    @OptionalField(key: "density") var density: FoodDensity?
    @OptionalField(key: "link_url") var linkUrl: String?
    @OptionalField(key: "prefilled_url") var prefilledUrl: String?
    @OptionalField(key: "image_ids") var imageIds: [UUID]?

    @Children(for: \.$parentUserFood) var foodItems: [FoodItem]
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

        let spawnedPresetFood: PresetFood?
        if let presetFoodId = form.info.spawnedPresetFoodId {
            guard let presetFood = try await PresetFood.find(presetFoodId, on: db) else {
                throw UserFoodDataError.nonExistentSpawnedPresetFood
            }
            spawnedPresetFood = presetFood
        } else {
            spawnedPresetFood = nil
        }
        
        guard !(spawnedUserFood != nil && spawnedPresetFood != nil) else {
            throw UserFoodDataError.bothSpawnedUserFoodAndPresetFoodWasProvided
        }

        let user = try await UserController.createOrFetchUser(cloudKitId: form.info.cloudKitId, in: db)
        guard let userId = user.id else {
            throw UserCreateError.unableToCreateOrFetchUserForCloudKitId
        }
        
        self.id = form.id
        self.$user.id = userId
        self.$spawnedUserFood.id = spawnedUserFood?.id
        self.$spawnedPresetFood.id = spawnedPresetFood?.id
        self.createdAt = Date().timeIntervalSince1970
        self.updatedAt = Date().timeIntervalSince1970

        self.foodType = .rawFood
        self.name = form.name
        self.emoji = form.emoji
        self.amount = form.info.amount
        self.nutrients = form.info.nutrients
        self.sizes = form.info.sizes
        self.publishStatus = form.publishStatus
        self.numberOfTimesConsumed = 0
        self.changes = []

        self.serving = form.info.serving
        self.detail = form.detail
        self.brand = form.brand
        self.density = form.info.density
        self.linkUrl = form.info.linkUrl
        self.prefilledUrl = form.info.prefilledUrl
        self.imageIds = form.info.imageIds
    }
}
