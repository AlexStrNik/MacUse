import AppKit
import ApplicationServices
import Claude

@Tool
struct GetWindowElementsOfRole {
    /// Returns all elements of specified role in a window with their values, labels and paths
    ///
    /// - Parameters:
    ///   - pid: Process ID of the application
    ///   - windowIndex: Index of the window to search in
    ///   - role: Accessibility role to search for. Common values include:
    ///     - AXButton: Buttons
    ///     - AXCheckBox: Checkboxes
    ///     - AXComboBox: Combo boxes
    ///     - AXGroup: Groups of elements
    ///     - AXImage: Images
    ///     - AXList: Lists
    ///     - AXMenu: Menus
    ///     - AXMenuBar: Menu bars
    ///     - AXMenuItem: Menu items
    ///     - AXPopUpButton: Pop-up buttons
    ///     - AXProgressIndicator: Progress bars
    ///     - AXRadioButton: Radio buttons
    ///     - AXScrollArea: Scroll areas
    ///     - AXSearchField: Search fields
    ///     - AXSlider: Sliders
    ///     - AXSplitGroup: Split views
    ///     - AXStaticText: Static text
    ///     - AXTabGroup: Tab groups
    ///     - AXTable: Tables
    ///     - AXTextArea: Text areas, also Search fields sometimes
    ///     - AXTextField: Text fields, also Search fields
    ///     - AXToolbar: Toolbars
    ///     - AXWindow: Windows
    ///
    /// Returns a list of elements in format:
    /// AXWindow[0].AXGroup[1].AXButton[0] (value: 1, label: Submit)
    ///
    /// Returns error message if window or elements not found
    func invoke(pid: pid_t, windowIndex: Int, role: String) async throws -> String {
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
        var elements: [(element: AXUIElement, path: String)] = []
        
        // Helper function to recursively find elements
        func findElements(in element: AXUIElement, currentPath: String) {
            guard let children = element.children else { return }
            
            var rolesMap: [String: Int] = [:]
            
            for child in children {
                let childRole = child.role
                if rolesMap[childRole] == nil {
                    rolesMap[childRole] = 0
                } else {
                    rolesMap[childRole]! += 1
                }
                let index = rolesMap[childRole]!
                
                let path = currentPath.isEmpty ? "\(childRole)[\(index)]" : "\(currentPath).\(childRole)[\(index)]"
                
                if childRole == role {
                    elements.append((child, path))
                }
                
                findElements(in: child, currentPath: path)
            }
        }
        
        // Start search from window
        findElements(in: window, currentPath: "")
        
        if elements.isEmpty {
            return "No elements with role \(role) found"
        }
        
        // Format output
        return elements.map { element, path in
            let value = AXUIElement.formatValue(element.attribute(kAXValueAttribute))
            let label = element.label

            var attrStr = ""
            var attributes: [String] = []

            if !value.isEmpty {
                attributes.append("value: \"\(value)\"")
            }
            if let label = label, !label.isEmpty {
                attributes.append("label: \"\(label)\"")
            }

            if !attributes.isEmpty {
                attrStr += " (\(attributes.joined(separator: ", ")))"
            }
            
            return "AXWindow[\(windowIndex)].\(path)\(attrStr)"
        }.joined(separator: "\n")
    }
}
