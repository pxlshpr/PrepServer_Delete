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

    init(deviceFood: PrepDataTypes.Food, userId: User.IDValue) {
        self.$user.id = userId
        self.id = deviceFood.id
        self.foodType = deviceFood.type
        self.name = deviceFood.name
        self.emoji = deviceFood.emoji
        self.detail = deviceFood.detail
        self.brand = deviceFood.brand
        
        self.amount = deviceFood.info.amount
        self.serving = deviceFood.info.serving
        self.nutrients = deviceFood.info.nutrients
        self.sizes = deviceFood.info.sizes
        self.density = deviceFood.info.density
        self.linkUrl = deviceFood.info.linkUrl
        self.prefilledUrl = deviceFood.info.prefilledUrl
        self.imageIds = deviceFood.info.imageIds

        self.publishStatus = deviceFood.publishStatus ?? .hidden
        
        self.numberOfTimesConsumed = 0
        self.createdAt = deviceFood.updatedAt
        self.updatedAt = deviceFood.updatedAt

        self.changes = []
        
        //TODO: Bring these back
        self.$spawnedUserFood.id = spawnedUserFood?.id
        self.$spawnedPresetFood.id = spawnedPresetFood?.id
    }

    init(_ form: UserFoodCreateForm, for db: Database, userId: User.IDValue) async throws {
        
        do {
            let _ = try form.validate()
        } catch let formError as UserFoodDataError {
            throw UserFoodCreateError.formError(formError)
        }
        
        //TODO: Fetch these and provide them outside this initializer
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
        
        self.id = form.id
        self.$user.id = userId
        self.$spawnedUserFood.id = spawnedUserFood?.id
        self.$spawnedPresetFood.id = spawnedPresetFood?.id
        self.createdAt = Date().timeIntervalSince1970
        self.updatedAt = Date().timeIntervalSince1970

        self.foodType = .food
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
