import Foundation

enum FileLocation {
    
    case holdingArea(FileType)
    case repository(FileType)
    
    func directoryPath(for id: String) -> String? {
        let path = FileManager.default.currentDirectoryPath
        switch self {
        case .holdingArea:
            return "\(path)/Public/Uploads/tmp"
        case .repository(let fileType):
            let suffix = id.suffix(6)
            guard suffix.count == 6 else { return nil }
            let folder1 = suffix.prefix(3)
            let folder2 = suffix.suffix(3)
            return "\(path)/Public/Uploads/\(fileType.directory)/\(folder1)/\(folder2)"
        }
    }
    
    var fileType: FileType {
        switch self {
        case .holdingArea(let fileType):
            return fileType
        case .repository(let fileType):
            return fileType
        }
    }
    
    func filePath(for id: String) -> String? {
        switch fileType {
        case .image:
            return filePathForImage(with: id)
        case .json:
            return filePathForJSON(with: id)
        }
    }
    
    func filePathForImage(with id: String, extension ext: String = "jpg") -> String? {
        guard let directoryPath = directoryPath(for: id) else { return nil }
        return "\(directoryPath)/\(id).\(ext)"
    }
    
    func filePathForJSON(with id: String) -> String? {
        guard let directoryPath = directoryPath(for: id) else { return nil }
        return "\(directoryPath)/\(id).json"
    }
}
