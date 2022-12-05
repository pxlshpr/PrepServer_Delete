import Foundation

// MARK: - Functions
@discardableResult
func shell(_ args: String..., returnStdOut: Bool = false, stdIn: Pipe? = nil) throws -> (Int32, Pipe) {
    return try shell(args, returnStdOut: returnStdOut, stdIn: stdIn)
}

@discardableResult
func shell(_ args: [String], returnStdOut: Bool = false, stdIn: Pipe? = nil) throws -> (Int32, Pipe) {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    task.arguments = args
    let pipe = Pipe()
    if returnStdOut {
        task.standardOutput = pipe
    }
    if let stdIn = stdIn {
        task.standardInput = stdIn
    }
    try task.run()
    task.waitUntilExit()
    return (task.terminationStatus, pipe)
}

extension Pipe {
    func string() -> String? {
        let data = self.fileHandleForReading.readDataToEndOfFile()
        let result: String?
        if let string = String(data: data, encoding: String.Encoding.utf8) {
            result = string
        } else {
            result = nil
        }
        return result
    }
}
