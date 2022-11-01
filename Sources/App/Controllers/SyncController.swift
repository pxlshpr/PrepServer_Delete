import Fluent
import Vapor
import PrepDataTypes

struct SyncController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let sync = routes.grouped("sync")
        sync.post(use: performSync)
    }
    
    func performSync(req: Request) async throws -> SyncForm {
        let syncForm = try req.content.decode(SyncForm.self)
        
        /// ** Process SyncForm request **
        /// *Updates*
        /// For each entity in updates
        /// If the entity doesn't exist, add it
        /// If the entity exists and `device.updatedAt > server.updatedAt`
        ///     update it with the received object (depending on type)—updatedAt flag will be updated to what device has

        /// *Deletions*
        /// For each entity in deletions, check if it exists first
        /// If `server.updatedAt < device.deletedAt` then
        ///     delete it it depending on the type (type choose if its a soft or hard deletion), for soft deletions, `deletedAt` set to device
        /// otherwise don't delete it (we'll be sending the user an update in the response)

        /// ** Construct SyncForm response**
        /// *Updates*
        /// Populate with all entities that have `server.updatedAt > device.versionTimestamp` (this will include new entities too)

        /// *Deletions*
        /// Populate with all entities that have `server.deletedAt > device.versionTimestamp`

        /// *VersionToken*
        /// Set as current timestamp
        /// Now return this

        return syncForm
//        let userFood = try await UserFood(createForm, for: req.db)
//        try await userFood.save(on: req.db)
//        guard let userFoodId = userFood.id else {
//            throw UserFoodCreateError.missingFoodId
//        }
//        for barcode in createForm.info.barcodes {
//            let barcode = Barcode(barcode: barcode, userFoodId: userFoodId)
//            try await barcode.save(on: req.db)
//        }
//        return .ok
    }
}

enum SyncError: Error {
}

extension SyncForm: Content {
    
}
