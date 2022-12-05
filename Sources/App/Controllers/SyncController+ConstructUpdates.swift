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
            .with(\.$goalSet)
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
            .with(\.$goalSet)
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
            .with(\.$meal) { meal in
                meal
                    .with(\.$day)
                    .with(\.$goalSet)
            }
            .with(\.$userFood) { userFood in
                userFood.with(\.$barcodes)
            }
            .with(\.$presetFood) { presetFood in
                presetFood.with(\.$barcodes)
            }
            .all()
            .compactMap { foodItem in
                PrepDataTypes.FoodItem(from: foodItem, db: db)
            }
        
        let childFoodItems = try await FoodItem.query(on: db)
            .join(UserFood.self, on: \FoodItem.$parentUserFood.$id == \UserFood.$id)
            .filter(UserFood.self, \.$user.$id == userId)
            .filter(\.$updatedAt > syncForm.versionTimestamp)
            .with(\.$parentUserFood) { parentUserFood in
                parentUserFood.with(\.$barcodes)
            }
            .with(\.$userFood) { userFood in
                userFood.with(\.$barcodes)
            }
            .with(\.$presetFood) { presetFood in
                presetFood.with(\.$barcodes)
            }
            .all()
            .compactMap { foodItem in
                
                PrepDataTypes.FoodItem(from: foodItem, db: db)
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

