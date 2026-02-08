import Foundation

/// A value type representing a blocked domain
/// Swift 6: Converted to struct for Sendable conformance and better value semantics
public struct BlockedDomain: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var name: String
    public var enabled: Bool

    // This is not a robust solution, but that's okay. I am bringing in favicons
    // mostly for decoration, so it's okay if the user sees a generic placeholder
    // instead from time to time.
    public var favicon: String {
        let baseDomain = name.drop(while: { !$0.isLetter && !$0.isNumber })
        return "https://\(baseDomain)/favicon.ico"
    }

    public init(id: UUID = UUID(), name: String, enabled: Bool = true) {
        self.id = id
        self.name = name
        self.enabled = enabled
    }
}

