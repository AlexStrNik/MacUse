import AppKit
import ApplicationServices
import Claude

@Tool
struct ApplicationWindows {
    /// Returns list of windows for the specified application process
    ///
    /// - Parameter pid: Process ID of the application to get windows for
    ///
    /// Returns window information in format:
    /// "Window Title" [Window Index]
    ///
    /// If the application has no windows or the process ID is invalid,
    /// returns "No visible windows found"
    func invoke(pid: pid_t) async throws -> String {
        let appRef = AXUIElementCreateApplication(pid)
        guard let windows = appRef.attribute(kAXWindowsAttribute) as? [AXUIElement] else {
            return "No visible windows found"
        }

        let windowInfos = windows.enumerated().compactMap { index, window -> String? in
            guard let title = window.title else { return nil }

            return "\"\(title)\" [\(index)]"
        }

        return windowInfos.isEmpty
            ? "No visible windows found" : windowInfos.joined(separator: "\n")
    }
}
