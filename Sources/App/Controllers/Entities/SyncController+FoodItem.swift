import Fluent
import Vapor
import PrepDataTypes

extension SyncController {

    func processUpdatedDeviceFoodItems(_ deviceFoodItems: [PrepDataTypes.FoodItem], on db: Database) async throws {
        for deviceFoodItem in deviceFoodItems {
            try await processUpdatedDeviceFoodItem(deviceFoodItem, on: db)
        }
    }

    func processUpdatedDeviceFoodItem(_ deviceFoodItem: PrepDataTypes.FoodItem, on db: Database) async throws {
        let serverFoodItem = try await FoodItem.query(on: db)
            .filter(\.$id == deviceFoodItem.id)
            .with(\.$userFood)
            .with(\.$presetFood)
            .with(\.$parentUserFood)
            .with(\.$meal)
            .first()
        
        if let deletedAt = deviceFoodItem.deletedAt, deletedAt > 0 {
            guard let serverFoodItem else { throw ServerSyncError.foodItemNotFound }
            try await deleteServerFoodItem(serverFoodItem, on: db)
        } else if let serverFoodItem {
            try await updateServerFoodItem(serverFoodItem, with: deviceFoodItem, on: db)
        } else {
            try await createNewServerFoodItem(with: deviceFoodItem, on: db)
        }
    }
    
    func updateServerFoodItem(
        _ serverFoodItem: FoodItem,
        with deviceFoodItem: PrepDataTypes.FoodItem,
        on db: Database
    ) async throws {
        
        let newUserFood: UserFood?
        let newPresetFood: PresetFood?
        /// If the `Food` doesn't match (check both `UserFood` and `PresetFood` for a matching `id`)
        if (deviceFoodItem.food.id != serverFoodItem.userFood?.id
            || deviceFoodItem.food.id != serverFoodItem.presetFood?.id)
        {
            /// Try getting the `UserFood first`
            guard let foodTuple = try await findFood(with: deviceFoodItem.food.id, on: db) else {
                throw ServerSyncError.foodNotFound
            }
            if let userFood = foodTuple.0 {
                newUserFood = userFood
                newPresetFood = nil
            } else {
                newUserFood = nil
                newPresetFood = foodTuple.1
            }
        } else {
            newUserFood = nil
            newPresetFood = nil
        }
        
        let newParentUserFood: UserFood?
        if let deviceParentFoodId = deviceFoodItem.parentFood?.id,
           let serverParentFoodId = serverFoodItem.parentUserFood?.id,
           serverParentFoodId != deviceParentFoodId
        {
            /// Find the new parent `UserFood`
            guard let parentUserFood = try await UserFood.find(deviceParentFoodId, on: db) else {
                throw ServerSyncError.foodNotFound
            }
            newParentUserFood = parentUserFood
        } else {
            newParentUserFood = nil
        }

        let newMeal: Meal?
        if let deviceMealId = deviceFoodItem.meal?.id,
           let serverMealId = serverFoodItem.meal?.id,
           serverMealId != deviceMealId
        {
            /// Find the new `Meal`
            guard let meal = try await Meal.find(deviceMealId, on: db) else {
                throw ServerSyncError.mealNotFound
            }
            newMeal = meal
        } else {
            newMeal = nil
        }
        
        try serverFoodItem.update(
            with: deviceFoodItem,
            newUserFoodId: try newUserFood?.requireID(),
            newPresetFoodId: try newPresetFood?.requireID(),
            newParentUserFoodId: try newParentUserFood?.requireID(),
            newMealId: try newMeal?.requireID()
        )
        
        try await serverFoodItem.update(on: db)
    }

    func createNewServerFoodItem(with deviceFoodItem: PrepDataTypes.FoodItem, on db: Database) async throws {
        let userFood: UserFood?
        let presetFood: PresetFood?
        
        guard let foodTuple = try await findFood(with: deviceFoodItem.food.id, on: db) else {
            throw ServerSyncError.foodNotFound
        }
        if let serverFood = foodTuple.0 {
            userFood = serverFood
            presetFood = nil
        } else {
            userFood = nil
            presetFood = foodTuple.1
        }
        
        let parentUserFood: UserFood?
        if let deviceParentFoodId = deviceFoodItem.parentFood?.id {
            guard let serverParentUserFood = try await UserFood.find(deviceParentFoodId, on: db) else {
                throw ServerSyncError.foodNotFound
            }
            parentUserFood = serverParentUserFood
        } else {
            parentUserFood = nil
        }

        let meal: Meal?
        if let deviceMealId = deviceFoodItem.meal?.id {
            guard let serverMeal = try await Meal.find(deviceMealId, on: db) else {
                throw ServerSyncError.mealNotFound
            }
            meal = serverMeal
        } else {
            meal = nil
        }

        let foodItem = FoodItem(
            deviceFoodItem: deviceFoodItem,
            userFoodId: try userFood?.requireID(),
            presetFoodId: try presetFood?.requireID(),
            parentUserFoodId: try parentUserFood?.requireID(),
            mealId: try meal?.requireID()
        )
        try await foodItem.save(on: db)
    }

    func deleteServerFoodItem(_ serverFoodItem: FoodItem, on db: Database) async throws {
        serverFoodItem.softDelete()
        try await serverFoodItem.update(on: db)
    }
}
