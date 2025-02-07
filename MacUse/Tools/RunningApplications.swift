import Claude
import AppKit

@Tool
struct RunningApplications {
    /// Returns list of running applications
    ///
    /// - Parameters:
    ///   - filter: return only applications that contains <filter> in name
    ///
    /// Format:
    /// Application Name - Process Identifier
    func invoke(filter: String?) async throws -> String {
        let apps = NSWorkspace.shared.runningApplications

        let lines: [String] = apps.map {
            "\($0.localizedName ?? "Unknown") - \($0.processIdentifier)"
        }
        return lines.filter {
            filter != nil ? $0.lowercased().contains(filter!.lowercased()) : true
        }.joined(separator: "\n")
    }
}
