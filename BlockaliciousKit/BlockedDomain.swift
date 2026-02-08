import Foundation

/// A value type representing a blocked domain
/// Swift 6: Converted to struct for Sendable conformance and better value semantics
public struct BlockedDomain: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var name: String
    public var enabled: Bool
    public var faviconURL: String?  // Cached favicon URL discovered via FaviconFinder

    public var favicon: String {
        faviconURL ?? "https://\(basename)/favicon.ico"
    }
    
    public var basename: String {
        String(name.drop(while: { !$0.isLetter && !$0.isNumber }))
    }

    public init(id: UUID = UUID(), name: String, enabled: Bool = true, faviconURL: String? = nil) {
        self.id = id
        self.name = name
        self.enabled = enabled
        self.faviconURL = faviconURL
    }
}

