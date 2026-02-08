import Foundation
import Combine
import SafariServices

/// Main view model of the app
@MainActor
public final class BLViewModel: ObservableObject {
    @Published public var domains: [BLDomain]
    @Published public var groups: [BLDomainGroup]
    @Published public var contentBlockerEnabled: Bool

    private var cancellable = Set<AnyCancellable>()
    private var groupsCancellable: AnyCancellable?
    private let storage = BLStorage()
    private let faviconService = FaviconService()

    public init() {
        // Load domains from app group container or from preseed file
        domains = BLStorage.loadDomains()
        groups = BLStorage.loadGroups()
        contentBlockerEnabled = true

        // Clean up any orphaned group references
        cleanupOrphanedReferences()

        // Autosave changes when domains are edited by the user
        cancellable.insert(
            $domains
                .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
                .sink { [weak self] _ in
                    guard let self else { return }
                    Task { await self.save() }
                }
        )

        // Autosave changes when groups are edited by the user
        cancellable.insert(
            $groups
                .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
                .sink { [weak self] _ in
                    guard let self else { return }
                    Task { await self.save() }
                }
        )

        // Load initial extension state
        Task { await updateExtensionState() }

        // Start discovering missing favicons in background
        discoverMissingFavicons()
    }

    @discardableResult
    public func add(domain: String = "*example.com") -> BLDomain.ID {
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

        // Remove from all groups
        for i in groups.indices {
            groups[i].domainIDs.removeAll { $0 == id }
        }
    }

    public func toggle(withID id: BLDomain.ID) {
        if let index = domains.firstIndex(where: { $0.id == id }) {
            domains[index].enabled.toggle()
        }
        Task { await save() }
    }

    public func save() async {
        Task { [domains, groups] in
            await storage.save(domains: domains, groups: groups)
            await updateExtensionState()
        }
    }

    public func updateExtensionState() async {
        let state = try? await SFContentBlockerManager.stateOfContentBlocker(withIdentifier: AppConstant.contentBlockerBundleId)
        contentBlockerEnabled = state?.isEnabled ?? false
    }

    /// Discovers and caches favicon URLs for all domains that don't have one
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

    // MARK: - Computed properties for organization

    public func domains(in group: BLDomainGroup) -> [BLDomain] {
        domains.filter { domain in group.domainIDs.contains(domain.id) }
    }

    public var ungroupedDomains: [BLDomain] {
        let groupedIDs = Set(groups.flatMap { $0.domainIDs })
        return domains.filter { !groupedIDs.contains($0.id) }
    }

    // MARK: - Group operations

    @discardableResult
    public func addGroup(name: String = "New Group") -> BLDomainGroup.ID {
        let group = BLDomainGroup(name: name)
        groups.append(group)
        return group.id
    }

    public func deleteGroup(withID id: BLDomainGroup.ID) {
        groups.removeAll { $0.id == id }
        // Domains become ungrouped automatically
    }

    public func renameGroup(withID id: BLDomainGroup.ID, to newName: String) {
        if let index = groups.firstIndex(where: { $0.id == id }) {
            groups[index].name = newName
        }
    }

    public func toggleGroup(withID id: BLDomainGroup.ID, enabled: Bool) {
        guard let group = groups.first(where: { $0.id == id }) else { return }

        for domainID in group.domainIDs {
            if let index = domains.firstIndex(where: { $0.id == domainID }) {
                domains[index].enabled = enabled
            }
        }

        Task { await save() }
    }

    public func addDomain(_ domainID: UUID, toGroup groupID: BLDomainGroup.ID) {
        // Remove from all groups first (no nesting)
        for i in groups.indices {
            groups[i].domainIDs.removeAll { $0 == domainID }
        }

        // Add to target group
        if let index = groups.firstIndex(where: { $0.id == groupID }) {
            if !groups[index].domainIDs.contains(domainID) {
                groups[index].domainIDs.append(domainID)
            }
        }
    }

    private func cleanupOrphanedReferences() {
        let domainIDs = Set(domains.map { $0.id })
        for i in groups.indices {
            groups[i].domainIDs.removeAll { !domainIDs.contains($0) }
        }
    }
}
