import Fluent
import Vapor
import PrepDataTypes

extension SyncController {

    func constructUpdates(for timestamp: Double) async -> SyncForm.Updates {
        /// *Updates*
        /// Populate with all entities that have `server.updatedAt > device.versionTimestamp` (this will include new entities too)
        SyncForm.Updates()
    }
    

}
