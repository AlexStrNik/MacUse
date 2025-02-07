//
//  QueryWindowElement.swift
//  MacUse
//
//  Created by Aleksandr Strizhnev on 06.02.2025.
//

import AppKit
import ApplicationServices
import Claude

@Tool
struct PrintWindowTree {
    /// Finds and prints information about a specific accessibility element using a query path
    ///
    /// - Parameters:
    ///   - pid: Process ID of the application
    ///   - query: Query string in format "AXWindow[index].AXRole[index].AXRole[index]" (e.g. "AXWindow[0].AXGroup[0].AXButton[1]")
    ///   - maxDepth: Maximum depth for printing children tree
    ///
    /// Returns element information and its children tree if found, or error message if not found
    /// Format of found element:
    /// AXRole (value: Value, label: Label)
    /// -- AXRole (value: Value, label: Label)
    func invoke(pid: pid_t, query: String, maxDepth: Int) async throws -> String {
        guard let app = NSRunningApplication(processIdentifier: pid) else {
            return "No application found with pid \(pid)"
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

        return currentElement.buildTree(maxDepth: maxDepth)
    }
}
