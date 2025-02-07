import Foundation
import Claude

@ToolInput
enum MemoryAction {
    case append(String)
    case read
}

@Tool
struct Memory {
    /// Stores and retrieves application-specific UI interaction patterns
    ///
    /// - Parameters:
    ///   - action: Action to perform:
    ///     - append: Add new memory entry
    ///     - read: Read all stored memories
    ///   - appName: Name of the application to store/retrieve memories for
    ///
    /// Memory entries should contain:
    /// - Query paths to important UI elements
    /// - Steps to perform common actions
    /// - Known issues or special handling required
    ///
    /// Returns stored memories for read action or confirmation for append
    func invoke(action: MemoryAction, appName: String) async throws -> String {
        let fileManager = FileManager.default
        let memoriesDir = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Downloads")
            .appendingPathComponent("Memories")
        
        // Create memories directory if needed
        try? fileManager.createDirectory(at: memoriesDir, withIntermediateDirectories: true)
        
        let appFile = memoriesDir.appendingPathComponent("\(appName).md")
        
        switch action {
        case .read:
            guard fileManager.fileExists(atPath: appFile.path) else {
                return "No memories found for \(appName)"
            }
            
            return try String(contentsOf: appFile, encoding: .utf8)
            
        case .append(let entry):
            var content = ""
            if fileManager.fileExists(atPath: appFile.path) {
                content = try String(contentsOf: appFile, encoding: .utf8)
                content += "\n\n"
            }
            
            // Add timestamp and format entry
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let timestamp = dateFormatter.string(from: Date())
            
            content += """
                ## Entry (\(timestamp))
                \(entry)
                """
            
            try content.write(to: appFile, atomically: true, encoding: .utf8)
            return "Memory added for \(appName)"
        }
    }
}
