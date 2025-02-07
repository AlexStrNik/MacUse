import AppKit
import ApplicationServices
import Claude

@Tool
struct FocusWindowElement {
    /// Focuses the specified accessibility element
    ///
    /// - Parameters:
    ///   - pid: Process ID of the application
    ///   - query: Query string in format "AXRole[index].AXRole[index]" (e.g. "AXWindow[0].AXTextField[0]")
    ///
    /// Note: For reliable interaction, call FocusWindow tool first to ensure
    /// the target window is active and in front.
    ///
    /// Returns success message or error if element not found or not focusable
    func invoke(pid: pid_t, query: String) async throws -> String {
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

        return "Successfully focused element: \(currentElement.role)"
    }
}
