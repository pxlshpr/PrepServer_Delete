import Fluent
import Vapor
import PrepDataTypes

struct UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let users = routes.grouped("users")
//        users.post("user_foods", use: userFoods)
    }
    
//    func userFoods(req: Request) async throws -> [UserFood] {
//        let params = try req.content.decode(UserFoodsForUserParams.self)
//        return try await User.query(on: req.db)
//            .filter(\.$id == params.userId)
//            .with(\.$userFoods)
//            .first()
//            .map { $0.userFoods } ?? []
//    }
}

extension UserController {
    static func createOrFetchUser(cloudKitId: String, in db: Database) async throws -> User {
        let users = try await User.query(on: db)
            .filter(\.$cloudKitId == cloudKitId)
            .all()
        
        guard let user = users.first else {
            /// Create and return a new User
            let newUser = User(cloudKitId: cloudKitId)
            try await newUser.save(on: db)
            return newUser
        }
        
        /// Make sure we only have 1 user for each `cloudKitId`
        guard  users.count == 1 else {
            throw UserCreateError.multipleUsersForCloudKitId
        }
        
        return user
    }
}

enum UserCreateError: Error {
    case unableToCreateOrFetchUserForCloudKitId
    case multipleUsersForCloudKitId
}
