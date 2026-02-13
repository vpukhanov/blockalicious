import Foundation
import SwiftUI
import SafariServices

/// Main view model of the app
@Observable
@MainActor
public final class BLViewModel {
    public var domains: [BLDomain] {
        didSet { scheduleSave() }
    }
    public var groups: [BLDomainGroup] {
        didSet { scheduleSave() }
    }
    public var contentBlockerEnabled: Bool

    @ObservationIgnored private var saveTask: Task<Void, Never>?
    @ObservationIgnored private let storage = BLStorage()
    @ObservationIgnored private let faviconService = FaviconService()

    public init() {
        // Clean up orphaned references on local copies before assigning
        // (direct assignment in init does not trigger didSet)
        var loadedGroups = BLStorage.loadGroups()
        let loadedDomains = BLStorage.loadDomains()
        let domainIDs = Set(loadedDomains.map { $0.id })
        for i in loadedGroups.indices {
            loadedGroups[i].domainIDs.removeAll { !domainIDs.contains($0) }
        }

        domains = loadedDomains
        groups = loadedGroups
        contentBlockerEnabled = true

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

    public func delete(withID id: UUID) {
        domains.removeAll { $0.id == id }
        groups.removeAll { $0.id == id }

        // Remove domain from all groups
        for i in groups.indices {
            groups[i].domainIDs.removeAll { $0 == id }
        }
    }

    public func toggle(withID id: UUID) {
        if let index = domains.firstIndex(where: { $0.id == id }) {
            domains[index].enabled.toggle()
        } else if let index = groups.firstIndex(where: { $0.id == id }) {
            toggleGroup(withID: groups[index].id, enabled: !isGroupEnabled(groups[index]))
        }
    }

    public func updateExtensionState() async {
        let state = try? await SFContentBlockerManager.stateOfContentBlocker(withIdentifier: AppConstant.contentBlockerBundleId)
        contentBlockerEnabled = state?.isEnabled ?? false
    }

    /// Discovers and caches favicon URLs for all domains that don't have one
    public func discoverMissingFavicons() {
        // Capture IDs to avoid index invalidation during iteration
        let idsToDiscover = domains.filter { $0.faviconURL == nil }.map(\.id)
        Task {
            for id in idsToDiscover {
                guard let domain = domains.first(where: { $0.id == id }) else { continue }

                if let faviconURL = await faviconService.discoverFaviconURL(for: domain.basename) {
                    if let currentIndex = domains.firstIndex(where: { $0.id == id }) {
                        domains[currentIndex].faviconURL = faviconURL
                    }
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

    // MARK: - Binding helpers for filtered views

    public func binding(forDomain domainID: UUID) -> Binding<BLDomain> {
        Binding(
            get: {
                self.domains.first(where: { $0.id == domainID })
                    ?? BLDomain(id: domainID, name: "", enabled: false)
            },
            set: { newValue in
                if let index = self.domains.firstIndex(where: { $0.id == domainID }) {
                    self.domains[index] = newValue
                }
            }
        )
    }

    public func binding(forGroup groupID: UUID) -> Binding<BLDomainGroup> {
        Binding(
            get: {
                self.groups.first(where: { $0.id == groupID })
                    ?? BLDomainGroup(id: groupID, name: "", domainIDs: [])
            },
            set: { newValue in
                if let index = self.groups.firstIndex(where: { $0.id == groupID }) {
                    self.groups[index] = newValue
                }
            }
        )
    }

    // MARK: - Group operations

    @discardableResult
    public func addGroup(domainIDs: Set<UUID>, name: String = "New Group") -> BLDomainGroup.ID {
        let group = BLDomainGroup(name: name)
        groups.append(group)

        for id in domainIDs {
            addDomain(id, toGroup: group.id)
        }

        return group.id
    }

    public func isGroupEnabled(_ group: BLDomainGroup) -> Bool {
        return domains(in: group).contains { $0.enabled }
    }

    public func toggleGroup(withID id: BLDomainGroup.ID, enabled: Bool) {
        guard let group = groups.first(where: { $0.id == id }) else { return }

        for domainID in group.domainIDs {
            if let index = domains.firstIndex(where: { $0.id == domainID }) {
                domains[index].enabled = enabled
            }
        }
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

    // MARK: - Private

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            await storage.save(domains: domains, groups: groups)
            await updateExtensionState()
        }
    }
}
