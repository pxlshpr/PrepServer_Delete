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
        /// Goal
        /// UserFood
        if let deviceFoods = updates.foods {
            try await updateFoods(with: deviceFoods, user: user, db: db)
        }
        
        /// Barcode
        /// TokenAward
        /// TokenRedemption
        /// Day
        if let deviceDays = updates.days {
            try await updateDays(with: deviceDays, user: user, db: db)
        }
        
        /// EnergyExpenditure
        /// Meal
        if let deviceMeals = updates.meals {
            try await updateMeals(with: deviceMeals, db: db)
        }

        /// FoodItem
        /// FoodUsage
        /// QuickMealItem

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
                    try updateServerMeal(serverMeal, with: deviceMeal, newDayId: newDay?.requireID())
                    try await serverMeal.update(on: db)
                } else {
                    /// If the day doesn't exist, add it
                    guard let day = try await Day.find(deviceMeal.day.id, on: db) else {
                        throw ServerSyncError.dayNotFound
                    }
                    
                    let meal = Meal(deviceMeal: deviceMeal, dayId: try day.requireID())
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
                    .with(\.$goal)
                    .first()

                /// If it exists, update it
                if let serverDay {
                    /// If the `Goal`'s don't match, fetch the new one and supply it to the `updateServerDay` function
                    let newGoal: Goal?
                    if let deviceGoalId = deviceDay.goal?.id,
                       serverDay.goal?.id != deviceGoalId
                    {
                        guard let goal = try await Goal.find(deviceGoalId, on: db) else {
                            throw ServerSyncError.goalNotFound
                        }
                        newGoal = goal
                    } else {
                        newGoal = nil
                    }

                    try updateServerDay(serverDay, with: deviceDay, newGoalId: newGoal?.requireID())
                    try await serverDay.update(on: db)
                } else {
                    /// If the day doesn't exist, add it

                    let goal: Goal?
                    /// If we were provided a `Goal`, make sure that we can fetch it first before creating the `Day`
                    if let goalId = deviceDay.goal?.id {
                        guard let serverGoal = try await Goal.find(goalId, on: db) else {
                            throw ServerSyncError.goalNotFound
                        }
                        goal = serverGoal
                    } else {
                        goal = nil
                    }
                    
                    let day = Day(
                        deviceDay: deviceDay,
                        userId: try user.requireID(),
                        goalId: try goal?.requireID()
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
    
    func updateServerMeal(_ serverMeal: Meal, with deviceMeal: PrepDataTypes.Meal, newDayId: Day.IDValue?) throws {
        if let newDayId {
            serverMeal.$day.id = newDayId
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

    func updateServerDay(_ serverDay: Day, with deviceDay: PrepDataTypes.Day, newGoalId: Goal.IDValue?) throws {
        if let newGoalId {
            serverDay.$goal.id = newGoalId
        }
        
        serverDay.addEnergyExpendituresToGoal = deviceDay.addEnergyExpendituresToGoal
        serverDay.goalBonusEnergySplit = deviceDay.goalBonusEnergySplit
        serverDay.goalBonusEnergySplitRatio = deviceDay.goalBonusEnergySplitRatio
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
        
        serverUser.preferredEnergyUnit = deviceUser.preferredEnergyUnit
        serverUser.prefersMetricUnit = deviceUser.prefersMetricUnits
        serverUser.explicitVolumeUnits = deviceUser.explicitVolumeUnits
        serverUser.bodyMeasurements = deviceUser.bodyMeasurements
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
