import Fluent
import Vapor
import PrepDataTypes

extension SyncController {

    /// Populate with all entities that have `server.updatedAt > device.versionTimestamp` (this will include new entities too)
    func constructUpdates(for syncForm: SyncForm, db: Database) async throws -> SyncForm.Updates {
        let days = try await updatedDays(for: syncForm, db: db)
        let meals = try await updatedMeals(for: syncForm, db: db)
        let foods = try await updatedUserFoods(for: syncForm, db: db)
        let foodItems = try await updatedFoodItems(for: syncForm, db: db)
        let goalSets = try await updatedGoalSets(for: syncForm, db: db)
        
        return SyncForm.Updates(
            user: try await updatedDeviceUser(for: syncForm, db: db),
            days: days,
            foods: foods,
            foodItems: foodItems,
            goalSets: goalSets,
            meals: meals
        )
    }
    
    func userId(from syncForm: SyncForm, db: Database) async throws -> UUID {
        /// If we have a `cloudKitId`, use that in case the user just started using a new device
        let userId: UUID
        if let deviceUser = syncForm.updates?.user,
           let serverUser = try await user(forDeviceUser: deviceUser, db: db),
           let id = serverUser.id
        {
            userId = id
        } else {
            userId = syncForm.userId
        }
        return userId
    }
    
    func updatedUserFoods(for syncForm: SyncForm, db: Database) async throws -> [PrepDataTypes.Food]? {
        let userId = try await userId(from: syncForm, db: db)
        return try await UserFood.query(on: db)
            .filter(\.$user.$id == userId)
            .filter(\.$updatedAt > syncForm.versionTimestamp)
            .with(\.$barcodes)
            .all()
            .compactMap { userFood in
                PrepDataTypes.Food(from: userFood)
            }
    }
    
    func updatedDays(for syncForm: SyncForm, db: Database) async throws -> [PrepDataTypes.Day]? {
        
        guard !syncForm.requestedCalendarDayStrings.isEmpty else {
            return []
        }
        
        let userId = try await userId(from: syncForm, db: db)
        return try await Day.query(on: db)
            .filter(\.$user.$id == userId)
            .filter(\.$calendarDayString ~~ syncForm.requestedCalendarDayStrings)
            .filter(\.$updatedAt > syncForm.versionTimestamp)
            .all()
            .compactMap { day in
                PrepDataTypes.Day(from: day)
            }
    }

    func updatedMeals(for syncForm: SyncForm, db: Database) async throws -> [PrepDataTypes.Meal]? {
        let userId = try await userId(from: syncForm, db: db)
        let meals = try await Meal.query(on: db)
            .join(Day.self, on: \Meal.$day.$id == \Day.$id)
            .filter(Day.self, \.$user.$id == userId)
            .filter(Day.self, \.$calendarDayString ~~ syncForm.requestedCalendarDayStrings)
            .filter(\.$updatedAt > syncForm.versionTimestamp)
            .with(\.$day)
            .all()
            .compactMap { meal in
                PrepDataTypes.Meal(from: meal)
            }
        
        if !meals.isEmpty {
            print("Returning meals for versionTimestamp: \(syncForm.versionTimestamp)")
            for meal in meals {
                print("  -> \(meal.name) — updatedAt: \(meal.updatedAt)")
            }
        }

        return meals
    }
    
    func updatedGoalSets(for syncForm: SyncForm, db: Database) async throws -> [PrepDataTypes.GoalSet]? {
        let userId = try await userId(from: syncForm, db: db)
        return try await GoalSet.query(on: db)
            .filter(\.$user.$id == userId)
            .filter(\.$updatedAt > syncForm.versionTimestamp)
            .all()
            .compactMap { goalSet in
                PrepDataTypes.GoalSet(from: goalSet)
            }
    }
    
    func updatedFoodItems(for syncForm: SyncForm, db: Database) async throws -> [PrepDataTypes.FoodItem]? {
        /// Similar to meals, get all the food items that have an attached meal within the requested date window
        /// Otherwise, if it has a parent food, return all of them irrespective of time
        /// So we need to create two separate queries here, and merge the results into one array

        let userId = try await userId(from: syncForm, db: db)
        let mealFoodItems = try await FoodItem.query(on: db)
            .join(Meal.self, on: \FoodItem.$meal.$id == \Meal.$id)
            .join(Day.self, on: \Meal.$day.$id == \Day.$id)
            .filter(Day.self, \.$user.$id == userId)
            .filter(Day.self, \.$calendarDayString ~~ syncForm.requestedCalendarDayStrings)
            .filter(\.$updatedAt > syncForm.versionTimestamp)
            .with(\.$meal)
            .with(\.$userFood)
            .with(\.$presetFood)
            .all()
            .compactMap { foodItem in
                PrepDataTypes.FoodItem(from: foodItem)
            }
        
        let childFoodItems = try await FoodItem.query(on: db)
            .join(UserFood.self, on: \FoodItem.$parentUserFood.$id == \UserFood.$id)
            .filter(UserFood.self, \.$user.$id == userId)
            .filter(\.$updatedAt > syncForm.versionTimestamp)
            .with(\.$parentUserFood)
            .with(\.$userFood)
            .with(\.$presetFood)
            .all()
            .compactMap { foodItem in
                PrepDataTypes.FoodItem(from: foodItem)
            }
        return mealFoodItems + childFoodItems
    }
    
    func updatedDeviceUser(for syncForm: SyncForm, db: Database) async throws -> PrepDataTypes.User? {
        
        let serverUser: App.User?
        if let deviceUser = syncForm.updates?.user {
            /// if we were provided with an updated user try and fetch it using that, as we may have a different `cloudKitId` being used on a new device (which will get subsequently updated)
            guard let user = try await user(forDeviceUser: deviceUser, db: db) else {
                return nil
            }
            serverUser = user
        } else {
            /// otherwise, grab the user from the provided user id in the sync form and return it if the `updatedAt` flag is later than the `versionTimestamp`
            guard let user = try await User.find(syncForm.userId, on: db) else {
                return nil
            }
            guard user.updatedAt > syncForm.versionTimestamp else {
                return nil
            }
            serverUser = user
        }
        
        guard let serverUser else { return nil }
        
        return PrepDataTypes.User(from: serverUser)
    }
}

extension PrepDataTypes.Barcode {
    init?(from serverBarcode: Barcode) {
        guard let id = serverBarcode.id else {
            return nil
        }
        self.init(
            id: id,
            payload: serverBarcode.payload,
            symbology: serverBarcode.symbology
        )
    }
}
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
            updatedAt: serverUserFood.updatedAt
        )
    }
    
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
            updatedAt: serverPresetFood.updatedAt
        )
    }
}

extension PrepDataTypes.GoalSet {
    init?(from serverGoalSet: GoalSet) {
        guard let id = serverGoalSet.id else {
            return nil
        }
        self.init(
            id: id,
            type: serverGoalSet.type,
            name: serverGoalSet.name,
            emoji: serverGoalSet.emoji,
            goals: serverGoalSet.goals,
            syncStatus: .synced,
            updatedAt: serverGoalSet.updatedAt
        )
    }
}

extension PrepDataTypes.Day {
    init?(from serverDay: Day) {
        guard let id = serverDay.id else {
            return nil
        }
        //TODO: Handle Goal
        //TODO: Check that bodyProfile is being handled properly
        self.init(
            id: id,
            calendarDayString: serverDay.calendarDayString,
            goalSet: nil,
            bodyProfile: serverDay.bodyProfile,
            meals: [],
            syncStatus: .synced,
            updatedAt: serverDay.updatedAt
        )
    }
}

extension PrepDataTypes.Meal {
    init?(from serverMeal: Meal) {
        guard let id = serverMeal.id,
              let day = PrepDataTypes.Day(from: serverMeal.day)
        else {
            return nil
        }
        self.init(
            id: id,
            day: day,
            name: serverMeal.name,
            time: serverMeal.time,
            markedAsEatenAt: serverMeal.markedAsEatenAt,
            foodItems: [],
            syncStatus: .synced,
            updatedAt: serverMeal.updatedAt,
            deletedAt: nil
        )
    }
}

extension PrepDataTypes.FoodItem {
    init?(from serverFoodItem: FoodItem) {
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
            deletedAt: nil
        )
    }
}

extension PrepDataTypes.User {
    init?(from serverUser: User) {
        guard let id = serverUser.id else {
            return nil
        }
        self.init(
            id: id,
            cloudKitId: serverUser.cloudKitId,
            units: serverUser.units,
            bodyProfile: serverUser.bodyProfile,
            syncStatus: .synced,
            updatedAt: serverUser.updatedAt
        )
    }
}
