import Foundation
import Combine
import SafariServices

class BlockedDomainsVim: ObservableObject {
    @Published var domains: [BlockedDomain]
    @Published var contentBlockerEnabled: Bool

    private var cancellable: AnyCancellable?

    init() {
        // Load domains from app group container or from preseed file
        domains =
                FileManager.default
                           .decode([BlockedDomain].self, from: "Domains.json", in: "BFJQQT3YDX.Blockalicious")
                ?? Bundle.main.decode([BlockedDomain].self, from: "DomainsPreseed.json")
                ?? []

        contentBlockerEnabled = true
        
        // Autosave changes when domains are edited by the user
        cancellable = $domains
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { _ in
                self.save()
            }
    }

    func add() -> BlockedDomain.ID {
        let domain = BlockedDomain(name: "*example.com")
        domains.append(domain)
        return domain.id
    }

    func delete(withID id: BlockedDomain.ID) {
        domains = domains.filter {
            $0.id != id
        }
    }

    func save() {
        guard let data = try? JSONEncoder().encode(domains) else {
            fatalError("Could not encode blocked domains.")
        }
        guard let url = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: "BFJQQT3YDX.Blockalicious")?
                                   .appendingPathComponent("Domains.json", isDirectory: false) else {
            fatalError("Could not request url for app group.")
        }
        try? data.write(to: url)
        BlockerListWriter.shared.write(domains: domains)
        
        SFContentBlockerManager.getStateOfContentBlocker(withIdentifier: BlockerListWriter.contentBlockerBundleId) { state, _ in
            if let state = state {
                DispatchQueue.main.async {
                    self.contentBlockerEnabled = state.isEnabled
                }
            }
        }
    }
}
