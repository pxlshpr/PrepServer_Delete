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

        await processSyncForm(deviceSyncForm)
        return await constructSyncForm(for: deviceSyncForm.versionTimestamp)
    }

    func processSyncForm(_ syncForm: SyncForm) async {
        if let updates = syncForm.updates {
            await processUpdates(updates, version: syncForm.versionTimestamp)
        }

        if let deletions = syncForm.deletions {
            await processDeletions(deletions, version: syncForm.versionTimestamp)
        }
    }
    
    /// ** Construct SyncForm response**
    func constructSyncForm(for versionTimestamp: Double) async -> SyncForm {
        SyncForm(
            updates: await constructUpdates(for: versionTimestamp),
            deletions: await constructDeletions(for: versionTimestamp),
            versionTimestamp: Date().timeIntervalSince1970
        )
    }
}

enum SyncError: Error {
}

extension SyncForm: Content {
    
}
