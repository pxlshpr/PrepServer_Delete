import Fluent
import Vapor
import PrepDataTypes

extension SyncController {

    /// Populate with all entities that have `server.updatedAt > device.versionTimestamp` (this will include new entities too)
    func constructUpdates(for syncForm: SyncForm, db: Database) async throws -> SyncForm.Updates {
        SyncForm.Updates(
            user: try await updatedDeviceUser(for: syncForm, db: db)
        )
    }
    
    func updatedDeviceUser(for syncForm: SyncForm, db: Database) async throws -> PrepDataTypes.User? {
        /// If we have a `cloudKitId`, use that in case the user just started using a new device
        guard let deviceUser = syncForm.updates?.user else {
            return nil
        }
        guard let serverUser = try await user(forDeviceUser: deviceUser, db: db) else {
            return nil
        }
        print("sending back serverUser with id: \(serverUser.id?.uuidString ?? "no uuid")")
        return PrepDataTypes.User(from: serverUser)
    }
}

extension PrepDataTypes.User {
    init?(from serverUser: User) {
        guard
            let id = serverUser.id,
            let updatedAt = serverUser.updatedAt
        else {
            return nil
        }
        self.init(
            id: id,
            cloudKitId: serverUser.cloudKitId,
            preferredEnergyUnit: serverUser.preferredEnergyUnit,
            prefersMetricUnits: serverUser.prefersMetricUnit,
            explicitVolumeUnits: serverUser.explicitVolumeUnits,
            bodyMeasurements: serverUser.bodyMeasurements,
            updatedAt: updatedAt.timeIntervalSince1970
        )
    }
}
