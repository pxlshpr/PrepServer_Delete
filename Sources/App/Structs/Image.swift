import Vapor
import Foundation

struct Image: Content {
    var id: String
    var data: Data
}
