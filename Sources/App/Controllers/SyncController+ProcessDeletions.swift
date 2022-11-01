import Fluent
import Vapor
import PrepDataTypes

extension SyncController {

    func processDeletions(_ deletions: SyncForm.Deletions, version: Double) async {
        /// *Deletions*
        /// For each entity in deletions, check if it exists first
        /// If `server.updatedAt < device.deletedAt` then
        ///     delete it it depending on the type (type choose if its a soft or hard deletion), for soft deletions, `deletedAt` set to device
        /// otherwise don't delete it (we'll be sending the user an update in the response)
    }
    
}
