import Fluent
import Vapor
import PrepDataTypes

struct UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let users = routes.grouped("users")
        users.post("user_foods", use: userFoods)
        users.post(use: create)
    }
    
    func create(req: Request) async throws -> User {
        let createForm = try req.content.decode(UserCreateForm.self)
        let user = User(createForm)
        try await user.save(on: req.db)
        return user
    }

    func userFoods(req: Request) async throws -> [UserFood] {
        let params = try req.content.decode(UserFoodsForUserParams.self)
        return try await User.query(on: req.db)
            .filter(\.$id == params.userId)
            .with(\.$foods)
            .first()
            .map { $0.foods } ?? []
    }
}

enum UserCreateError: Error {
}
