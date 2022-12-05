import Fluent
import Vapor

func routes(_ app: Application) throws {
    try app.register(collection: SyncController())
    
    app.get("hello") { req in
        try shell("pg_dump", "-U", "pxlshpr", "prep", ">", "~/prep-backup-\(Date().timestamp).sql")
        return "We here"
    }
}
