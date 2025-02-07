import Claude
import AppKit

@Tool
struct InstalledApplications {
    /// Returns list of installed applications
    ///
    /// - Parameters:
    ///   - filter: return only applications that contains <filter> in name
    ///
    /// Format:
    /// Application Name - URL
    func invoke(filter: String?) async throws -> String {
        var applications: [(name: String, url: URL)] = []
        guard let enumerator = FileManager.default.enumerator(
            at: URL(filePath: "/Applications"),
            includingPropertiesForKeys: nil,
            options: [.skipsPackageDescendants]
        ) else {
            return "Failed to enumerate Applications directory"
        }
        
        for case let url as URL in enumerator {
            guard url.pathExtension == "app" else { continue }
            
            let name = url.deletingPathExtension().lastPathComponent
            applications.append((name: name, url: url))
        }
        
        guard let enumerator = FileManager.default.enumerator(
            at: URL(filePath: "/System/Applications"),
            includingPropertiesForKeys: nil,
            options: [.skipsPackageDescendants]
        ) else {
            return "Failed to enumerate Applications directory"
        }
        
        for case let url as URL in enumerator {
            guard url.pathExtension == "app" else { continue }
            
            let name = url.deletingPathExtension().lastPathComponent
            applications.append((name: name, url: url))
        }
        
        let lines = applications
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            .map { "\($0.name) - \($0.url.path())" }
            .filter {
                filter != nil ? $0.lowercased().contains(filter!.lowercased()) : true
            }
        
        return lines.isEmpty ? "No applications found" : lines.joined(separator: "\n")
    }
}
