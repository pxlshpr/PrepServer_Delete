import Fluent
import Vapor

func routes(_ app: Application) throws {
    try app.register(collection: SyncController())
    
    app.get("hello") { req in
        try shell("pwd")
        return "We here"
    }
}
