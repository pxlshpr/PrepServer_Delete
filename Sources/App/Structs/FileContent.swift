import Vapor
import Foundation

struct FileContent: Content {
    var id: String
    var data: Data
}
