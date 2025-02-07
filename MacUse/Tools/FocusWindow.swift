import AppKit
import ApplicationServices
import Claude

@Tool
struct FocusWindow {
    /// Brings the specified window to front and gives it focus
    ///
    /// - Parameters:
    ///   - pid: Process ID of the application
    ///   - windowIndex: Index of the window to focus
    ///
    /// Returns success message or error if window not found
    func invoke(pid: pid_t, windowIndex: Int) async throws -> String {
        guard let app = NSRunningApplication(processIdentifier: pid) else {
            return "No application found with pid \(pid)"
        }

        let appRef = AXUIElementCreateApplication(pid)
        guard let windows = appRef.attribute(kAXWindowsAttribute) as? [AXUIElement],
            windowIndex < windows.count
        else {
            return "Window with index \(windowIndex) not found"
        }

        let window = windows[windowIndex]
        
        // Activate the application first
        guard app.activate(options: .activateIgnoringOtherApps) else {
            return "Failed to activate application"
        }
        
        // Raise the window to front
        let raiseResult = AXUIElementPerformAction(window, kAXRaiseAction as CFString)
        guard raiseResult == .success else {
            return "Failed to raise window: \(raiseResult)"
        }
        
        return "Successfully focused window"
    }
}
