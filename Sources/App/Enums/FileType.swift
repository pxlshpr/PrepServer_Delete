import Foundation

enum FileType {
    case image, json
    
    var directory: String {
        switch self {
        case .image: return "images"
        case .json: return "jsons"
        }
    }
}
