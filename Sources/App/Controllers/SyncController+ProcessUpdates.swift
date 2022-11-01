import Fluent
import Vapor
import PrepDataTypes

extension SyncController {
    
    /// For each entity in updates
    /// If the entity doesn't exist, add it
    /// If the entity exists and `device.updatedAt > server.updatedAt`
    ///     update it with the received object (depending on type)—updatedAt flag will be updated to what device has
    func processUpdates(_ updates: SyncForm.Updates, version: Double, db: Database) async throws {
        do {
            if let user = updates.user {
                try await processUpdatedUser(user, db: db)
            }
        } catch {
            throw ServerSyncError.processUpdatesError
        }
    }
    
    func processUpdatedUser(_ deviceUser: PrepDataTypes.User, db: Database) async throws {
        if let user = try await User.find(deviceUser.id, on: db) {
            
        } else {
            /// If the user doesn't exist, add it
            let user = User(deviceUser: deviceUser)
        }
    }
}

enum ServerSyncError: Error {
    case processUpdatesError
}
