import Fluent
import Vapor
import PrepDataTypes

final class FoodItem: Model, Content {
    static let schema = "food_items"
    
    @ID(key: .id) var id: UUID?
    @OptionalParent(key: "user_food_id") var userFood: UserFood?
    @OptionalParent(key: "preset_food_id") var presetFood: PresetFood?
    @OptionalParent(key: "parent_user_food_id") var parentUserFood: UserFood?
    @OptionalParent(key: "meal_id") var meal: Meal?
    @Field(key: "created_at") var createdAt: Double
    @Field(key: "updated_at") var updatedAt: Double
    @OptionalField(key: "deleted_at") var deletedAt: Double?

    @Field(key: "amount") var amount: FoodValue
    @Field(key: "sort_position") var sortPosition: Int16
    @OptionalField(key: "marked_as_eaten_at") var markedAsEatenAt: Double?

    init() { }
    
    init(
        deviceFoodItem: PrepDataTypes.FoodItem,
        
        userFoodId: UserFood.IDValue?,
        presetFoodId: PresetFood.IDValue?,
        parentUserFoodId: UserFood.IDValue?,
        mealId: Meal.IDValue?
    ) {
        self.id = deviceFoodItem.id
        
        self.$userFood.id = userFoodId
        self.$presetFood.id = presetFoodId
        self.$parentUserFood.id = parentUserFoodId
        self.$meal.id = mealId
        
        let timestamp = Date().timeIntervalSince1970
        self.createdAt = timestamp
        self.updatedAt = timestamp
        self.deletedAt = nil
       
        self.amount = deviceFoodItem.amount
        self.sortPosition = Int16(deviceFoodItem.sortPosition)
        self.markedAsEatenAt = deviceFoodItem.markedAsEatenAt
    }
    
    func update(
        with deviceFoodItem: PrepDataTypes.FoodItem,
        newUserFoodId: UserFood.IDValue?,
        newPresetFoodId: PresetFood.IDValue?,
        newParentUserFoodId: UserFood.IDValue?,
        newMealId: Meal.IDValue?
    ) throws {
        
        /// If we were provided a `UserFood` id, then set that and unset the `PresetFood`
        if let newUserFoodId {
            self.$userFood.id = newUserFoodId
            self.$presetFood.id = nil
        }
        /// If we were provided a `PresetFood` id, then set that and unset the `UserFood`
        if let newPresetFoodId {
            self.$userFood.id = nil
            self.$presetFood.id = newPresetFoodId
        }
        /// Note that we're unable to unset both the `UserFood` and `PresetFood` as
        /// a `FoodItem` is always related to either one of those
        
        /// If a different parent `UserFood` id was provided, set that
        if let newParentUserFoodId {
            self.$parentUserFood.id = newParentUserFoodId
        }
        /// Note that we're unable to unset the parent `UserFood` as once a `FoodItem` is used
        /// as a food's child (for a plate or a recipe), it cannot then be changed to instead be a meal item

        /// If a new `Meal` id was provided, set that
        if let newMealId {
            self.$meal.id = newMealId
        }
        /// Note that we're unable to set this as once a fooditem has been assigned to a meal,
        /// it can only change between meals (and not be repurposed as a Food's child item)

        self.amount = deviceFoodItem.amount
        self.sortPosition = Int16(deviceFoodItem.sortPosition)
        self.markedAsEatenAt = deviceFoodItem.markedAsEatenAt
        
        self.updatedAt = Date().timeIntervalSince1970
    }

    func softDelete() {
        let timestamp = Date().timeIntervalSince1970
        self.deletedAt = timestamp
        self.updatedAt = timestamp
    }
}

//MARK: - FoodItem → PrepDataTypes.FoodItem

extension PrepDataTypes.FoodItem {
    init?(from serverFoodItem: FoodItem, db: Database) {
        guard let id = serverFoodItem.id else {
            return nil
        }

        /// Get the `Food` converted from either the  server's `UserFood` or `PresetFood`
        let food: Food
        if let userFood = serverFoodItem.userFood {
            guard let foodFromUserFood = PrepDataTypes.Food(from: userFood) else {
                return nil
            }
            food = foodFromUserFood
        } else {
            guard
                let presetFood = serverFoodItem.presetFood,
                let foodFromPresetFood = PrepDataTypes.Food(from: presetFood)
            else {
                return nil
            }
            food = foodFromPresetFood
        }

        /// If we have a meal, get it
        let meal: PrepDataTypes.Meal?
        if let serverMeal = serverFoodItem.meal {
            meal = PrepDataTypes.Meal(from: serverMeal)
        } else {
            meal = nil
        }

        /// If we have a parent food, get it
        let parentFood: PrepDataTypes.Food?
        if let serverParentUserFood = serverFoodItem.parentUserFood {
            parentFood = PrepDataTypes.Food(from: serverParentUserFood)
        } else {
            parentFood = nil
        }

        self.init(
            id: id,
            food: food,
            parentFood: parentFood,
            meal: meal,
            amount: serverFoodItem.amount,
            markedAsEatenAt: serverFoodItem.markedAsEatenAt,
            sortPosition: Int(serverFoodItem.sortPosition),
            syncStatus: .synced,
            updatedAt: serverFoodItem.updatedAt,
            deletedAt: serverFoodItem.deletedAt
        )
    }
}

//MARK: - UserFood → PrepDataTypes.Food

extension PrepDataTypes.Food {
    init?(from serverUserFood: UserFood) {
        guard let id = serverUserFood.id else {
            return nil
        }

        //TODO: Get these from the `FoodUsage`
        /// [ ] `numberOfTimesConsumedGlobally`
        /// [ ] `numberOfTimesConsumed`
        /// [ ] `lastUsedAt`
        /// [ ] `firstUsedAt`

        //TODO: Construct this
        /// [ ] `barcodes`

        //TODO: Make sure these are included in the query and set
        /// [ ] `spawnedUserFoodId`
        /// [ ] `spawnedPresetFoodId`

        //TODO: Revist these and check that we're returning the correct values
        /// [ ] `jsonSyncStatus`
        /// [ ] `childrenFoods`
        /// [ ] `dataSet`

        let barcodes: [PrepDataTypes.Barcode] = serverUserFood.barcodes.compactMap {
            PrepDataTypes.Barcode(from: $0)
        }
        
        let foodBarcodes = barcodes.map {
            FoodBarcode(payload: $0.payload, symbology: $0.symbology)
        }

        let info = FoodInfo(
            amount: serverUserFood.amount,
            serving: serverUserFood.serving,
            nutrients: serverUserFood.nutrients,
            sizes: serverUserFood.sizes,
            density: serverUserFood.density,
            linkUrl: serverUserFood.linkUrl,
            prefilledUrl: serverUserFood.prefilledUrl,
            imageIds: serverUserFood.imageIds,
            barcodes: foodBarcodes,
            spawnedUserFoodId: nil,
            spawnedPresetFoodId: nil
        )
        
        self.init(
            id: id,
            type: serverUserFood.foodType,
            name: serverUserFood.name,
            emoji: serverUserFood.emoji,
            detail: serverUserFood.detail,
            brand: serverUserFood.brand,
            numberOfTimesConsumedGlobally: 0,
            numberOfTimesConsumed: 0,
            lastUsedAt: nil,
            firstUsedAt: nil,
            info: info,
            publishStatus: serverUserFood.publishStatus,
            jsonSyncStatus: .synced,
            childrenFoods: nil,
            dataset: nil,
            barcodes: barcodes,
            syncStatus: .synced,
            updatedAt: serverUserFood.updatedAt,
            deletedAt: serverUserFood.deletedAt
        )
    }
}

//MARK: - PresetFood → PrepDataTypes.Food

extension PrepDataTypes.Food {
    init?(from serverPresetFood: PresetFood) {
        guard let id = serverPresetFood.id else {
            return nil
        }

        //TODO: Get these from the `FoodUsage`
        /// [ ] `numberOfTimesConsumedGlobally`
        /// [ ] `numberOfTimesConsumed`
        /// [ ] `lastUsedAt`
        /// [ ] `firstUsedAt`

        //TODO: Construct this
        /// [ ] `barcodes`

        //TODO: Make sure these are included in the query and set
        /// [ ] `spawnedUserFoodId`
        /// [ ] `spawnedPresetFoodId`

        //TODO: Revist these and check that we're returning the correct values
        /// [ ] `jsonSyncStatus`
        /// [ ] `childrenFoods`
        /// [ ] `dataSet`

        let barcodes: [PrepDataTypes.Barcode] = serverPresetFood.barcodes.compactMap {
            PrepDataTypes.Barcode(from: $0)
        }
        
        let foodBarcodes = barcodes.map {
            FoodBarcode(payload: $0.payload, symbology: $0.symbology)
        }

        let info = FoodInfo(
            amount: serverPresetFood.amount,
            serving: serverPresetFood.serving,
            nutrients: serverPresetFood.nutrients,
            sizes: serverPresetFood.sizes,
            density: serverPresetFood.density,
            barcodes: foodBarcodes,
            spawnedUserFoodId: nil,
            spawnedPresetFoodId: nil
        )
        
        
        self.init(
            id: id,
            type: .food,
            name: serverPresetFood.name,
            emoji: serverPresetFood.emoji,
            detail: serverPresetFood.detail,
            brand: serverPresetFood.brand,
            numberOfTimesConsumedGlobally: 0,
            numberOfTimesConsumed: 0,
            lastUsedAt: nil,
            firstUsedAt: nil,
            info: info,
            publishStatus: nil,
            jsonSyncStatus: .synced,
            childrenFoods: nil,
            dataset: serverPresetFood.dataset,
            barcodes: barcodes,
            syncStatus: .synced,
            updatedAt: serverPresetFood.updatedAt,
            deletedAt: serverPresetFood.deletedAt
        )
    }
}
