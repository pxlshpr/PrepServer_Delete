import Fluent
import Vapor
import PrepDataTypes

extension SyncController {
 
    func constructDeletions(for timestamp: Double) async -> SyncForm.Deletions {
        /// *Deletions*
        /// Populate with all entities that have `server.deletedAt > device.versionTimestamp`
        SyncForm.Deletions()
    }
    
}
