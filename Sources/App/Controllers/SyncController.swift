import Fluent
import Vapor
import PrepDataTypes

struct SyncController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let sync = routes.grouped("sync")
        sync.post(use: performSync)
    }
    
    func performSync(req: Request) async throws -> SyncForm {
        let deviceSyncForm = try req.content.decode(SyncForm.self)

        try await processSyncForm(deviceSyncForm, db: req.db)
        return try await constructSyncForm(for: deviceSyncForm, db: req.db)
    }

    func processSyncForm(_ syncForm: SyncForm, db: Database) async throws {
        if let updates = syncForm.updates {
            try await processUpdates(
                updates,
                for: syncForm.userId,
                version: syncForm.versionTimestamp,
                db: db
            )
        }

        if let deletions = syncForm.deletions {
            await processDeletions(deletions, version: syncForm.versionTimestamp)
        }
    }
    
    /// ** Construct SyncForm response**
    func constructSyncForm(for syncForm: SyncForm, db: Database) async throws -> SyncForm {
        SyncForm(
            updates: try await constructUpdates(for: syncForm.userId, after: syncForm.versionTimestamp, db: db),
            deletions: await constructDeletions(for: syncForm.versionTimestamp),
            userId: try await userId(for: syncForm, db: db),
            versionTimestamp: Date().timeIntervalSince1970
        )
    }
    
    func userId(for syncForm: SyncForm, db: Database) async throws -> UUID {
        
        if let deviceCloudKitId = syncForm.updates?.user?.cloudKitId {
            /// If this syncForm contained a `User` update with a `cloudKitId`—find and return the `User` using that
            ///
            guard
                let user = try await user(forCloudKitId: deviceCloudKitId, db: db),
                let userId = user.id
            else {
                throw ServerSyncError.couldNotGetUserIdForCloudKitId(deviceCloudKitId)
            }
            return userId
        } else {
            
            /// Otherwise, just return the `userId` that was provided
            return syncForm.userId
        }
    }
}


enum ServerSyncError: Error {
    case newCloudKitIdReceivedForUser(String)
    case processUpdatesError(String? = nil)
    case couldNotGetUserIdForCloudKitId(String)
}

extension SyncForm: Content {
    
}
