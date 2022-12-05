import Fluent
import Vapor

func routes(_ app: Application) throws {
    try app.register(collection: SyncController())
    
    app.get("backup") { req in
        try shell("./backup.sh")
        return HTTPStatus.ok
    }
}
