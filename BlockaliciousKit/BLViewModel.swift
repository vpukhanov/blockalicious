import Foundation
import Combine
import SafariServices

/// Main view model of the app
@MainActor
public final class BLViewModel: ObservableObject {
    @Published public var domains: [BLDomain]
    @Published public var contentBlockerEnabled: Bool

    private var cancellable: AnyCancellable?
    private let storage = DomainStorage()
    private let faviconService = FaviconService()

    public init() {
        // Load domains from app group container or from preseed file
        domains = DomainStorage.loadDomains()
        contentBlockerEnabled = true

        // Autosave changes when domains are edited by the user
        cancellable = $domains
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                Task { await self.save() }
            }

        // Load initial extension state
        Task { await updateExtensionState() }

        // Start discovering missing favicons in background
        discoverMissingFavicons()
    }

    @discardableResult
    public func add() -> BLDomain.ID {
        add(domain: "*example.com")
    }

    @discardableResult
    public func add(domain: String) -> BLDomain.ID {
        let blocked = BLDomain(name: domain)
        domains.append(blocked)

        // Discover favicon in background
        Task {
            if let faviconURL = await faviconService.discoverFaviconURL(for: blocked.basename) {
                if let index = domains.firstIndex(where: { $0.id == blocked.id }) {
                    domains[index].faviconURL = faviconURL
                }
            }
        }

        return blocked.id
    }

    public func delete(withID id: BLDomain.ID) {
        domains.removeAll { $0.id == id }
    }

    public func toggle(withID id: BLDomain.ID) {
        if let index = domains.firstIndex(where: { $0.id == id }) {
            domains[index].enabled.toggle()
        }
        Task { await save() }
    }

    public func save() async {
        Task { [domains] in
            await storage.save(domains: domains)
            await updateExtensionState()
        }
    }

    public func updateExtensionState() async {
        let state = try? await SFContentBlockerManager.stateOfContentBlocker(withIdentifier: AppConstant.contentBlockerBundleId)
        contentBlockerEnabled = state?.isEnabled ?? false
    }

    /// Discovers and caches favicon URLs for all domains that don't have one
    /// Runs in background without blocking UI
    public func discoverMissingFavicons() {
        Task {
            for i in domains.indices where domains[i].faviconURL == nil {
                // Discover favicon URL in background
                if let faviconURL = await faviconService.discoverFaviconURL(for: domains[i].basename) {
                    domains[i].faviconURL = faviconURL
                }

                // Small delay between requests to avoid overwhelming the network
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
    }
}
