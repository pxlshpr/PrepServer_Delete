import Fluent
import Vapor
import PrepDataTypes

extension SyncController {

    /// Populate with all entities that have `server.updatedAt > device.versionTimestamp` (this will include new entities too)
    func constructUpdates(for syncForm: SyncForm, db: Database) async throws -> SyncForm.Updates {
        let days = try await updatedDays(for: syncForm, db: db)
        let meals = try await updatedMeals(for: syncForm, db: db)
        let foods = try await updatedUserFoods(for: syncForm, db: db)
        
        return SyncForm.Updates(
            user: try await updatedDeviceUser(for: syncForm, db: db),
            days: days,
            foods: foods,
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
}

extension PrepDataTypes.Day {
    init?(from serverDay: Day) {
        guard let id = serverDay.id else {
            return nil
        }
        //TODO: Handle Goal
        self.init(
            id: id,
            calendarDayString: serverDay.calendarDayString,
            goal: nil,
            addEnergyExpendituresToGoal: serverDay.addEnergyExpendituresToGoal,
            goalBonusEnergySplit: serverDay.goalBonusEnergySplit,
            goalBonusEnergySplitRatio: serverDay.goalBonusEnergySplitRatio,
            energyExpenditures: [],
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

extension PrepDataTypes.User {
    init?(from serverUser: User) {
        guard let id = serverUser.id else {
            return nil
        }
        self.init(
            id: id,
            cloudKitId: serverUser.cloudKitId,
            preferredEnergyUnit: serverUser.preferredEnergyUnit,
            prefersMetricUnits: serverUser.prefersMetricUnit,
            explicitVolumeUnits: serverUser.explicitVolumeUnits,
            bodyMeasurements: serverUser.bodyMeasurements,
            syncStatus: .synced,
            updatedAt: serverUser.updatedAt
        )
    }
}
