import Fluent
import Vapor
import PrepDataTypes

extension SyncController {
    
    func processUpdatedDeviceGoalSets(_ deviceGoalSets: [PrepDataTypes.GoalSet], user: User, on db: Database) async throws {
        do {
            for deviceGoalSet in deviceGoalSets {
                try await processUpdatedDeviceGoalSet(deviceGoalSet, user: user, on: db)
            }
        } catch {
            throw ServerSyncError.processUpdatesError(error.localizedDescription)
        }
    }
    
    func processUpdatedDeviceGoalSet(_ deviceGoalSet: PrepDataTypes.GoalSet, user: User, on db: Database) async throws {
        
        let serverGoalSet = try await GoalSet.query(on: db)
            .filter(\.$id == deviceGoalSet.id)
            .first()

        if let deletedAt = deviceGoalSet.deletedAt, deletedAt > 0 {
            guard let serverGoalSet else { throw ServerSyncError.goalSetNotFound }
            try await deleteServerGoalSet(serverGoalSet, on: db)
        } else if let serverGoalSet {
            try await updateServerGoalSet(serverGoalSet, with: deviceGoalSet, on: db)
        } else {
            try await createNewServerGoalSet(with: deviceGoalSet, user: user, on: db)
        }
    }
    
    func deleteServerGoalSet(_ serverGoalSet: GoalSet, on db: Database) async throws {
        serverGoalSet.softDelete()
        try await serverGoalSet.update(on: db)
    }
    
    func updateServerGoalSet(_ serverGoalSet: GoalSet, with deviceGoalSet: PrepDataTypes.GoalSet, on db: Database) async throws {
        try serverGoalSet.update(with: deviceGoalSet)
        try await serverGoalSet.update(on: db)
    }
    
    func createNewServerGoalSet(with deviceGoalSet: PrepDataTypes.GoalSet, user: User, on db: Database) async throws {
        let goalSet = GoalSet(deviceGoalSet: deviceGoalSet, userId: try user.requireID())
        try await goalSet.save(on: db)
    }

}
