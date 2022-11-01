import Fluent
import Vapor
import PrepDataTypes

extension SyncController {
    
    /// For each entity in updates
    /// If the entity doesn't exist, add it
    /// If the entity exists and `device.updatedAt > server.updatedAt`
    ///     update it with the received object (depending on type)—updatedAt flag will be updated to what device has
    func processUpdates(_ updates: SyncForm.Updates, for userId: UUID, version: Double, db: Database) async throws {
        if let user = updates.user {
            try await processUpdatedUser(user, db: db)
        }
    }
    
    func processUpdatedUser(_ deviceUser: PrepDataTypes.User, db: Database) async throws {
        do {
            /// Find the user by checking either the `id` or the `cloudKitId` if it exists.
            if let serverUser = try await user(for: deviceUser, db: db) {
                try updateExistingUser(serverUser, with: deviceUser)
                try await serverUser.update(on: db)
            } else {
                /// If the user doesn't exist, add it
                let user = User(deviceUser: deviceUser)
                try await user.save(on: db)
            }
        } catch {
            throw ServerSyncError.processUpdatesError(error.localizedDescription)
        }
    }
    
    func updateExistingUser(_ serverUser: User, with deviceUser: PrepDataTypes.User) throws {
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
        
        if deviceUser.id != serverUser.id {
            /// If the ids don't match (because the user logged in on a new device)
            /// reset the `updatedAt` timestamp forwards so that it gets included in the `SyncForm` we will be responding with
            serverUser.updatedAt = Date()
        } else {
            serverUser.updatedAt = Date(timeIntervalSince1970: deviceUser.updatedAt)
        }
    }

    func user(forCloudKitId cloudKitId: String, db: Database) async throws -> User? {
        try await User.query(on: db)
            .filter(\.$cloudKitId == cloudKitId)
            .first()
    }

    func user(for deviceUser: PrepDataTypes.User, db: Database) async throws -> User? {
        if let cloudKitId = deviceUser.cloudKitId {
            return try await user(forCloudKitId: cloudKitId, db: db)
        } else {
            return try await User.find(deviceUser.id, on: db)
        }
    }
}
