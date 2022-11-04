import Fluent
import Vapor
import PrepDataTypes

extension SyncController {

    /// Populate with all entities that have `server.updatedAt > device.versionTimestamp` (this will include new entities too)
    func constructUpdates(for syncForm: SyncForm, db: Database) async throws -> SyncForm.Updates {
        let days = try await updatedDays(for: syncForm, db: db)
        let meals = try await updatedMeals(for: syncForm, db: db)
        
        return SyncForm.Updates(
            user: try await updatedDeviceUser(for: syncForm, db: db),
            days: days,
            meals: meals
        )
    }
    
    
    func updatedDays(for syncForm: SyncForm, db: Database) async throws -> [PrepDataTypes.Day]? {
        
        guard !syncForm.requestedCalendarDayStrings.isEmpty else {
            return []
        }
        
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
        
        return try await Meal.query(on: db)
            .join(Day.self, on: \Meal.$day.$id == \Day.$id)
            .filter(Day.self, \.$user.$id == userId)
            .filter(Day.self, \.$calendarDayString ~~ syncForm.requestedCalendarDayStrings)
            .filter(\.$updatedAt > syncForm.versionTimestamp)
            .with(\.$day)
            .all()
            .compactMap { meal in
                PrepDataTypes.Meal(from: meal)
            }
    }

    func updatedDeviceUser(for syncForm: SyncForm, db: Database) async throws -> PrepDataTypes.User? {
        /// If we have a `cloudKitId`, use that in case the user just started using a new device
        guard let deviceUser = syncForm.updates?.user else {
            return nil
        }
        guard let serverUser = try await user(forDeviceUser: deviceUser, db: db) else {
            return nil
        }
        return PrepDataTypes.User(from: serverUser)
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
        //TODO: Handle Goal
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
