import Foundation

func saveFile(_ file: FileContent, type: FileType, to location: FileLocation) {
    
    guard let filePath = location.filePath(for: file.id),
          let directoryPath = location.directoryPath(for: file.id) else {
        print("Couldn't get paths")
        return
    }
    
    if !FileManager.default.fileExists(atPath: directoryPath) {
        do {
            print("Creating: \(directoryPath)")
            try FileManager.default.createDirectory(atPath: directoryPath, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Error creating directory: \(error.localizedDescription)");
        }
    }
    
    let result = FileManager.default.createFile(atPath: filePath, contents: file.data, attributes: nil)
    print("saving at \(filePath)")
    print("success: \(result)")
}
