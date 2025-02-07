import AppKit
import ApplicationServices
import Claude

@Tool
struct SendKeystrokesToWindowElement {
    /// Sends keystrokes to the specified accessibility element. Sends return keystroke automatically after specified text
    ///
    /// - Parameters:
    ///   - pid: Process ID of the application
    ///   - query: Query string in format "AXRole[index].AXRole[index]" (e.g. "AXWindow[0].AXTextField[0]")
    ///   - keystrokes: Text to type into the element. No modifiers are supported
    ///
    /// Note: For reliable interaction, call FocusWindow tool first to ensure
    /// the target window is active and in front.
    ///
    /// Returns success message or error if element not found or not focusable
    func invoke(pid: pid_t, query: String, keystrokes: String) async throws -> String {
        guard let app = NSRunningApplication(processIdentifier: pid) else {
            return "No application found with pid \(pid)"
        }
        
        // Activate the application first
        guard app.activate(options: .activateIgnoringOtherApps) else {
            return "Failed to activate application"
        }

        let appRef = AXUIElementCreateApplication(pid)
        let components = query.components(separatedBy: ".")

        var currentElement: AXUIElement = appRef

        for component in components {
            guard let (role, index) = parseQueryComponent(component) else {
                return "Invalid query format at: \(component)"
            }

            guard let children = currentElement.children,
                index < children.count
            else {
                return "No children found for: \(component)"
            }

            let matchingChildren = children.filter { $0.role == role }
            guard index < matchingChildren.count else {
                return "Index \(index) out of bounds for role \(role)"
            }

            currentElement = matchingChildren[index]
        }

        // Set focus using AXFocusedAttribute
        let focusResult = AXUIElementSetAttributeValue(
            currentElement, kAXFocusedAttribute as CFString, true as CFTypeRef)
        guard focusResult == .success else {
            return "Failed to focus element: \(focusResult)"
        }

        // Escape special characters in the keystrokes string
        let escapedKeystrokes = keystrokes.replacingOccurrences(of: "\"", with: "\\\"")

        // Create and run the AppleScript
        let script = """
            tell application "System Events"
                keystroke "\(escapedKeystrokes)"
                keystroke return
            end tell
            """

        let process = Process()
        process.executableURL = URL(filePath: "/usr/bin/osascript")
        process.arguments = ["-e", script]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus != 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let error = String(data: data, encoding: .utf8) {
                    return "Failed to send keystrokes: \(error)"
                } else {
                    return "Failed to send keystrokes with status: \(process.terminationStatus)"
                }
            }
        } catch {
            return "Failed to execute osascript: \(error)"
        }

        return "Successfully sent keystrokes to element: \(currentElement.role)"
    }
}
