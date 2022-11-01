import Fluent
import Vapor
import PrepDataTypes

extension SyncController {

    func processUpdates(_ updates: SyncForm.Updates, version: Double) async {
        /// ** Process SyncForm request **
        /// *Updates*
        /// For each entity in updates
        /// If the entity doesn't exist, add it
        /// If the entity exists and `device.updatedAt > server.updatedAt`
        ///     update it with the received object (depending on type)—updatedAt flag will be updated to what device has
    }
    
}
