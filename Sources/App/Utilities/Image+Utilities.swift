import Foundation

func saveImage(_ image: Image, to location: ImageLocation = .holdingArea) {
    guard let filePath = location.filePath(for: image.id),
          let directoryPath = location.directoryPath(for: image.id) else {
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
    
    let result = FileManager.default.createFile(atPath: filePath, contents: image.data, attributes: nil)
    print("saving at \(filePath)")
    print("success: \(result)")
}
