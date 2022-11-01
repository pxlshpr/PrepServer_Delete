import Fluent
import Vapor
import PrepDataTypes

extension SyncController {

    /// Populate with all entities that have `server.updatedAt > device.versionTimestamp` (this will include new entities too)
    func constructUpdates(for userId: UUID, after timestamp: Double, db: Database) async throws -> SyncForm.Updates {
        SyncForm.Updates(
            user: updatedDeviceUser
        )
    }
    
    var updatedDeviceUser: PrepDataTypes.User? {
        nil
    }
}
