import Foundation
import Combine
import SafariServices

public class BlockedDomainsVim: ObservableObject {
    @Published public var domains: [BlockedDomain]
    @Published public var contentBlockerEnabled: Bool

    private var cancellable: AnyCancellable?

    public init() {
        // Load domains from app group container or from preseed file
        domains = FileManager.default
            .decode([BlockedDomain].self, from: "Domains.json", in: BlockerListWriter.securityGroupId)
                ?? Bundle(for: BlockedDomainsVim.self).decode([BlockedDomain].self, from: "DomainsPreseed.json")
                ?? []

        contentBlockerEnabled = true
        
        // Autosave changes when domains are edited by the user
        cancellable = $domains
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { _ in
                self.save()
            }
    }

    @discardableResult public func add() -> BlockedDomain.ID {
        add(domain: "*example.com")
    }
    
    @discardableResult public func add(domain: String) -> BlockedDomain.ID {
        let domain = BlockedDomain(name: domain)
        domains.append(domain)
        return domain.id
    }

    public func delete(withID id: BlockedDomain.ID) {
        domains = domains.filter {
            $0.id != id
        }
    }
    
    public func toggle(withID id: BlockedDomain.ID) {
        if let domain = domains.first(where: { $0.id == id }) {
            objectWillChange.send()
            domain.enabled = !domain.enabled
            save()
        }
    }

    public func save() {
        guard let data = try? JSONEncoder().encode(domains) else {
            fatalError("Could not encode blocked domains.")
        }
        guard let url = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: BlockerListWriter.securityGroupId)?
               .appendingPathComponent("Domains.json", isDirectory: false) else {
            fatalError("Could not request url for app group.")
        }
        try? data.write(to: url)
        BlockerListWriter.shared.write(domains: domains)
        
        updateExtensionState()
    }
    
    public func updateExtensionState() {
        SFContentBlockerManager.getStateOfContentBlocker(withIdentifier: BlockerListWriter.contentBlockerBundleId) { state, _ in
            if let state = state {
                DispatchQueue.main.async {
                    self.contentBlockerEnabled = state.isEnabled
                }
            }
        }
    }
}
