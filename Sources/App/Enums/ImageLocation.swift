import Foundation

enum ImageLocation {
    case holdingArea
    case repository
    
    func directoryPath(for imageId: String) -> String? {
        let path = FileManager.default.currentDirectoryPath
        switch self {
        case .holdingArea:
            return "\(path)/Public/Uploads/tmp"
        case .repository:
            let suffix = imageId.suffix(6)
            guard suffix.count == 6 else { return nil }
            let folder1 = suffix.prefix(3)
            let folder2 = suffix.suffix(3)
            return "\(path)/Public/Uploads/images/\(folder1)/\(folder2)"
        }
    }
    
    func filePath(for imageId: String) -> String? {
        guard let directoryPath = directoryPath(for: imageId) else { return nil }
        return "\(directoryPath)/\(imageId).jpg"
    }
}
