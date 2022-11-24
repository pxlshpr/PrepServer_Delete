import Fluent
import Vapor
import PrepDataTypes

extension SyncController {
    
    /// For each entity in updates
    /// If the entity doesn't exist, add it
    /// If the entity exists and `device.updatedAt > server.updatedAt`
    ///     update it with the received object (depending on type)—updatedAt flag will be updated to what device has
    func processUpdates(_ updates: SyncForm.Updates, for userId: UUID, version: Double, db: Database) async throws {
        
        /// We will need a user to proceed with the updates
        let user: User?
        
        /// First see if there was a `User` update provided—and if so,
        /// use the returned object as it may have a different `userId` in the case where the user logged in on a new device
        /// (and since the update may come with multiple accompanying updates—its crucial that we grab the correct `User` entity,
        /// without blindly trying to find the user with the provided `userId`)
        if let deviceUser = updates.user {
            user = try await updateUser(with: deviceUser, db: db)
        } else {
            /// If an updated wasn't provided, look for the user for the `userId` included in the `SyncForm`
            user = try await User.find(userId, on: db)
        }
        /// Before proceeding, make sure we have a `User` object
        guard let user else {
            throw ServerSyncError.userNotFound
        }
        
        /// Now update the entities in the correct order to account for prerequisites
        /// GoalSet
        //TODO: GoalSet
        
        /// UserFood
        if let deviceFoods = updates.foods {
            try await updateFoods(with: deviceFoods, user: user, db: db)
        }
        
        /// Barcode
        //TODO: Barcode
        
        /// TokenAward
        //TODO: TokenAward
        
        /// TokenRedemption
        //TODO: TokenRedemption
        
        /// Day
        if let deviceDays = updates.days {
            try await updateDays(with: deviceDays, user: user, db: db)
        }
        
        /// Meal
        if let deviceMeals = updates.meals {
            try await updateMeals(with: deviceMeals, db: db)
        }

        /// FoodItem
        //TODO: FoodItem
        
        /// FoodUsage
        //TODO: FoodUsage
        
        /// QuickMealItem
        //TODO: QuickMealItem

    }
    
    func updateMeals(with deviceMeals: [PrepDataTypes.Meal], db: Database) async throws {
        do {
            for deviceMeal in deviceMeals {
                let serverMeal = try await Meal.query(on: db)
                    .filter(\.$id == deviceMeal.id)
                    .with(\.$day)
                    .first()
                
                /// If it exists, update it
                if let serverMeal {
                    /// If the `Day`'s don't match, fetch the new one and supply it to the `updateServerMeal` function
                    let newDay: Day?
                    if serverMeal.day.id != deviceMeal.day.id {
                        guard let day = try await Day.find(deviceMeal.day.id, on: db) else {
                            throw ServerSyncError.dayNotFound
                        }
                        newDay = day
                    } else {
                        newDay = nil
                    }
                    
                    /// If the `GoalSet`'s don't match, fetch the new one and supply it to the `updateServerMeal` function
                    let newGoalSet: GoalSet?
                    if let deviceGoalSetId = deviceMeal.goalSet?.id,
                       serverMeal.goalSet?.id != deviceGoalSetId
                    {
                        guard let goalSet = try await GoalSet.find(deviceGoalSetId, on: db) else {
                            throw ServerSyncError.goalSetNotFound
                        }
                        newGoalSet = goalSet
                    } else {
                        newGoalSet = nil
                    }

                    try updateServerMeal(serverMeal, with: deviceMeal, newDayId: newDay?.requireID(), newGoalSetId: newGoalSet?.requireID())
                    try await serverMeal.update(on: db)
                } else {
                    /// If the meal doesn't exist, add it
                    guard let day = try await Day.find(deviceMeal.day.id, on: db) else {
                        throw ServerSyncError.dayNotFound
                    }
                    
                    let goalSet: GoalSet?
                    /// If we were provided a `GoalSet`, make sure that we can fetch it first before creating the `Meal`
                    if let goalSetId = deviceMeal.goalSet?.id {
                        guard let serverGoalSet = try await GoalSet.find(goalSetId, on: db) else {
                            throw ServerSyncError.goalSetNotFound
                        }
                        goalSet = serverGoalSet
                    } else {
                        goalSet = nil
                    }

                    let meal = Meal(
                        deviceMeal: deviceMeal,
                        dayId: try day.requireID(),
                        goalSetId: try goalSet?.requireID()
                    )
                    try await meal.save(on: db)
                }
            }
        } catch {
            throw ServerSyncError.processUpdatesError(error.localizedDescription)
        }
    }
    
    func updateFoods(with deviceFoods: [PrepDataTypes.Food], user: User, db: Database) async throws {
        do {
            for deviceFood in deviceFoods {
                
                /// Foods only ever get inserted or deleted—so we make sure it doesn't exist first
                let serverFood = try await UserFood.find(deviceFood.id, on: db)
                guard serverFood == nil else { continue }
                
                let userFood = UserFood(deviceFood: deviceFood, userId: try user.requireID())
                try await userFood.save(on: db)

                if let deviceBarcodes = deviceFood.barcodes {
                    for deviceBarcode in deviceBarcodes {
                        let barcode = Barcode(deviceBarcode: deviceBarcode, userFoodId: try userFood.requireID())
                        try await barcode.save(on: db)
                    }
                }
            }
        } catch {
            throw ServerSyncError.processUpdatesError(error.localizedDescription)
        }
    }
    
    func updateDays(with deviceDays: [PrepDataTypes.Day], user: User, db: Database) async throws {
        do {
            for deviceDay in deviceDays {
                
                let serverDay = try await Day.query(on: db)
                    .filter(\.$id == deviceDay.id)
                    .with(\.$goalSet)
                    .first()

                /// If it exists, update it
                if let serverDay {
                    /// If the `GoalSet`'s don't match, fetch the new one and supply it to the `updateServerDay` function
                    let newGoalSet: GoalSet?
                    if let deviceGoalSetId = deviceDay.goalSet?.id,
                       serverDay.goalSet?.id != deviceGoalSetId
                    {
                        guard let goalSet = try await GoalSet.find(deviceGoalSetId, on: db) else {
                            throw ServerSyncError.goalSetNotFound
                        }
                        newGoalSet = goalSet
                    } else {
                        newGoalSet = nil
                    }

                    try updateServerDay(serverDay, with: deviceDay, newGoalSetId: newGoalSet?.requireID())
                    try await serverDay.update(on: db)
                } else {
                    /// If the day doesn't exist, add it

                    let goalSet: GoalSet?
                    /// If we were provided a `GoalSet`, make sure that we can fetch it first before creating the `Day`
                    if let goalSetId = deviceDay.goalSet?.id {
                        guard let serverGoalSet = try await GoalSet.find(goalSetId, on: db) else {
                            throw ServerSyncError.goalSetNotFound
                        }
                        goalSet = serverGoalSet
                    } else {
                        goalSet = nil
                    }
                    
                    let day = Day(
                        deviceDay: deviceDay,
                        userId: try user.requireID(),
                        goalSetId: try goalSet?.requireID()
                    )
                    try await day.save(on: db)
                }
            }
        } catch {
            throw ServerSyncError.processUpdatesError(error.localizedDescription)
        }
    }
    
    func updateUser(with deviceUser: PrepDataTypes.User, db: Database) async throws -> User {
        do {
            /// Find the user by checking either the `id` or the `cloudKitId` if it exists.
            if let serverUser = try await user(forDeviceUser: deviceUser, db: db) {
                try updateServerUser(serverUser, with: deviceUser)
                try await serverUser.update(on: db)
                return serverUser
            } else {
                /// If the user doesn't exist, add it
                let user = User(deviceUser: deviceUser)
                try await user.save(on: db)
                return user
            }
        } catch {
            throw ServerSyncError.processUpdatesError(error.localizedDescription)
        }
    }
    
    func updateServerMeal(_ serverMeal: Meal, with deviceMeal: PrepDataTypes.Meal, newDayId: Day.IDValue?, newGoalSetId: GoalSet.IDValue?) throws {
        if let newDayId {
            serverMeal.$day.id = newDayId
        }
        if let newGoalSetId {
            serverMeal.$goalSet.id = newGoalSetId
        }
        serverMeal.updatedAt = deviceMeal.updatedAt
        serverMeal.name = deviceMeal.name
        serverMeal.time = deviceMeal.time
        if let markedAsEatenAt = deviceMeal.markedAsEatenAt {
            serverMeal.markedAsEatenAt = markedAsEatenAt
        } else {
            serverMeal.markedAsEatenAt = nil
        }
    }

    func updateServerDay(_ serverDay: Day, with deviceDay: PrepDataTypes.Day, newGoalSetId: GoalSet.IDValue?) throws {
        if let newGoalSetId {
            serverDay.$goalSet.id = newGoalSetId
        }
        
        serverDay.bodyProfile = deviceDay.bodyProfile
        serverDay.updatedAt = deviceDay.updatedAt
    }
    
    func updateServerUser(_ serverUser: User, with deviceUser: PrepDataTypes.User) throws {
        
        if deviceUser.id != serverUser.id {
            /// If the ids don't match (because the user logged in on a new device)
            /// reset the `updatedAt` timestamp forwards so that it gets included in the `SyncForm` we will be responding with
            serverUser.updatedAt = Date().timeIntervalSince1970
            print("Server user updated at is now: \(serverUser.updatedAt)")
        } else {
            serverUser.updatedAt = deviceUser.updatedAt
        }

        /// If we have a `cloudKitId` and it doesn't match what was received
        /// throw an error (it's assumed to never change once a user sets it)
        if let serverCloudKitId = serverUser.cloudKitId,
           serverCloudKitId != deviceUser.cloudKitId
        {
            throw ServerSyncError.newCloudKitIdReceivedForUser(deviceUser.id.uuidString)
        } else {
            serverUser.cloudKitId = deviceUser.cloudKitId
        }
        
        serverUser.units = deviceUser.units
        serverUser.bodyProfile = deviceUser.bodyProfile
    }

    func user(forCloudKitId cloudKitId: String, db: Database) async throws -> User? {
        try await User.query(on: db)
            .filter(\.$cloudKitId == cloudKitId)
            .first()
    }

    func user(forDeviceUser deviceUser: PrepDataTypes.User, db: Database) async throws -> User? {
        if let cloudKitId = deviceUser.cloudKitId {
            return try await user(forCloudKitId: cloudKitId, db: db)
        } else {
            return try await User.find(deviceUser.id, on: db)
        }
    }
}
