import Foundation

class BlockedDomain: Identifiable, ObservableObject, Codable {
    var id: UUID
    
    @Published var name: String
    @Published var enabled: Bool
    
    // This is not a robust solution, but that's okay. I am bringing in favicons
    // mostly for decoration, so it's okay if the user sees a generic placeholder
    // instead from time to time.
    var favicon: String {
        let baseDomain = name.drop(while: { !$0.isLetter && !$0.isNumber })
        return "https://\(baseDomain)/favicon.ico"
    }

    enum CodingKeys: CodingKey {
        case id, name, enabled
    }

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.enabled = true
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        enabled = try container.decode(Bool.self, forKey: .enabled)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(enabled, forKey: .enabled)
    }
}

