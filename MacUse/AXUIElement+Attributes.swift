import ApplicationServices

extension AXUIElement {
    func attribute(_ attribute: String) -> AnyObject? {
        var attributeValue: AnyObject?
        AXUIElementCopyAttributeValue(
            self,
            attribute as CFString,
            &attributeValue
        )

        return attributeValue
    }

    var attributes: [String: AnyObject] {
        var attributes: CFArray?
        AXUIElementCopyAttributeNames(self, &attributes)

        guard let attributes else {
            return [:]
        }

        return (attributes as! [String]).reduce(into: [:]) { result, attribute in
            let value = self.attribute(attribute)
            result[attribute as String] = value
        }
    }

    var description: String? {
        return attribute(kAXDescription) as? String
    }

    var title: String? {
        return attribute(kAXTitleAttribute) as? String
    }

    var role: String {
        return attribute(kAXRoleAttribute) as? String ?? "Unknown"
    }

    var prefferedLanguage: String? {
        return attribute("AXPreferredLanguage") as? String
    }

    var frame: CGRect {
        var frameValue: CFTypeRef?
        AXUIElementCopyAttributeValue(
            self,
            "AXFrame" as CFString,
            &frameValue
        )

        var frame = CGRect.zero

        guard let frameValue else {
            return frame
        }

        AXValueGetValue(
            frameValue as! AXValue,
            AXValueType.cgRect,
            &frame
        )

        return frame
    }

    var children: [AXUIElement]? {
        var count: CFIndex = 0
        var result = AXUIElementGetAttributeValueCount(
            self, kAXChildrenAttribute as CFString, &count)

        var children: CFArray?
        result = AXUIElementCopyAttributeValues(
            self, kAXChildrenAttribute as CFString, 0, count, &children)
        if result != .success {
            return nil
        }

        return children as? [AXUIElement]
    }

    func buildTree(depth: Int = 0, maxDepth: Int) -> String {
        guard depth <= maxDepth else { return "" }

        let indent = String(repeating: "-- ", count: depth)
        let role = self.role
        let value = Self.formatValue(attribute(kAXValueAttribute))
        let label = self.label

        var result = "\(indent)\(role)"
        var attributes: [String] = []

        if !value.isEmpty {
            attributes.append("value: \"\(value)\"")
        }
        if let label = label, !label.isEmpty {
            attributes.append("label: \"\(label)\"")
        }

        if !attributes.isEmpty {
            result += " (\(attributes.joined(separator: ", ")))"
        }

        result += "\n"

        if let children = self.children {
            result +=
                children
                .map { $0.buildTree(depth: depth + 1, maxDepth: maxDepth) }
                .joined()
        }

        return result
    }
    
    var label: String? {
        if let label = attribute(kAXLabelValueAttribute) as? String, !label.isEmpty {
            return label
        }
        if let description = attribute(kAXDescriptionAttribute) as? String, !description.isEmpty {
            return description
        }
        if let title = attribute(kAXTitleAttribute) as? String, !title.isEmpty {
            return title
        }
        if let identifier = attribute(kAXIdentifierAttribute) as? String, !identifier.isEmpty {
            return identifier
        }
        
        return nil
    }

    static func formatValue(_ value: AnyObject?) -> String {
        guard let value = value else { return "" }

        switch value {
        case let number as NSNumber:
            return number.stringValue
        case let string as String:
            return string
        case let array as [AnyObject]:
            return array.map { formatValue($0) }.joined(separator: ", ")
        case let axValue as AXValue:
            var point = CGPoint.zero
            var size = CGSize.zero
            var range = CFRange()
            var rect = CGRect.zero

            switch AXValueGetType(axValue) {
            case .cgPoint:
                AXValueGetValue(axValue, .cgPoint, &point)
                return "(\(point.x), \(point.y))"
            case .cgSize:
                AXValueGetValue(axValue, .cgSize, &size)
                return "\(size.width)×\(size.height)"
            case .cfRange:
                AXValueGetValue(axValue, .cfRange, &range)
                return "\(range.location)..\(range.location + range.length)"
            case .cgRect:
                AXValueGetValue(axValue, .cgRect, &rect)
                return "(\(rect.origin.x), \(rect.origin.y), \(rect.width), \(rect.height))"
            default:
                return "unknown value"
            }
        default:
            return "unknown value"
        }
    }
}

func parseQueryComponent(_ component: String) -> (role: String, index: Int)? {
    guard let match = component.firstMatch(of: /([A-Za-z]+)\[(\d+)\]/) else {
        return nil
    }

    let role = String(match.1)
    guard let index = Int(match.2) else {
        return nil
    }

    return (role, index)
}
