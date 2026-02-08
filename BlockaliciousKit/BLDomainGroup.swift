import Foundation

/// A value type representing a group of domains
public struct BLDomainGroup: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var name: String
    public var domainIDs: [UUID]  // References to BLDomain.id values

    public init(id: UUID = UUID(), name: String, domainIDs: [UUID] = []) {
        self.id = id
        self.name = name
        self.domainIDs = domainIDs
    }
}
