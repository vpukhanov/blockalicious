import Foundation
import Combine
import SafariServices

/// View model managing the list of blocked domains
/// Swift 6: Isolated to MainActor since it's an ObservableObject that updates UI
@MainActor
public final class BlockedDomainsVim: ObservableObject {
    @Published public var domains: [BlockedDomain]
    @Published public var contentBlockerEnabled: Bool

    private var cancellable: AnyCancellable?
    private let storage = DomainStorage()

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
    }

    @discardableResult
    public func add() -> BlockedDomain.ID {
        add(domain: "*example.com")
    }

    @discardableResult
    public func add(domain: String) -> BlockedDomain.ID {
        let domain = BlockedDomain(name: domain)
        domains.append(domain)
        return domain.id
    }

    public func delete(withID id: BlockedDomain.ID) {
        domains.removeAll { $0.id == id }
    }

    public func toggle(withID id: BlockedDomain.ID) {
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
        let state = try? await SFContentBlockerManager.stateOfContentBlocker(withIdentifier: BlockerListConstants.contentBlockerBundleId)
        contentBlockerEnabled = state?.isEnabled ?? false
    }
}

/// Handles persistent storage and Safari content blocker operations
/// Swift 6: Actor ensures thread-safe access to file I/O and Safari APIs
actor DomainStorage {
    nonisolated static func loadDomains() -> [BlockedDomain] {
        // Try loading from app group container
        if let domains = FileManager.default.decode(
            [BlockedDomain].self,
            from: "Domains.json",
            in: BlockerListConstants.securityGroupId
        ) {
            return domains
        }

        // Fall back to preseed file
        if let domains = Bundle(for: BlockedDomainsVim.self).decode(
            [BlockedDomain].self,
            from: "DomainsPreseed.json"
        ) {
            return domains
        }

        return []
    }

    func save(domains: [BlockedDomain]) async {
        // Save domains list
        await saveDomainsList(domains)

        // Generate and save Safari content blocker format
        await writeBlockerList(domains: domains)

        // Reload Safari extension
        try? await SFContentBlockerManager.reloadContentBlocker(withIdentifier: BlockerListConstants.contentBlockerBundleId)
    }

    private func saveDomainsList(_ domains: [BlockedDomain]) async {
        guard let data = try? JSONEncoder().encode(domains) else {
            assertionFailure("Could not encode blocked domains")
            return
        }

        guard let url = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: BlockerListConstants.securityGroupId
        )?.appendingPathComponent("Domains.json", isDirectory: false) else {
            assertionFailure("Could not get app group container URL")
            return
        }

        try? data.write(to: url)
    }

    private func writeBlockerList(domains: [BlockedDomain]) async {
        var names = domains.filter(\.enabled).map { $0.name.lowercased() }

        // Safari doesn't like the content blocker config with an empty "if-domain" list.
        // When you pass an empty list, it uses the previously cached value instead of the new one,
        // so if all domain blocks are disabled within the app, they are not really all disabled.
        // Passing the empty list as the fileContents all together doesn't seem to fix the issue
        // as well.
        // Hence when the user doesn't block any domains, we are blocking a non existing domain
        // so that Safari is satisfied with a config.
        if names.isEmpty {
            names = ["non1.existent2.domain3"]
        }

        guard
            let data = try? JSONEncoder().encode(names),
            let namesJson = String(data: data, encoding: .utf8)
        else {
            assertionFailure("Unable to JSON-encode domain names")
            return
        }

        guard let fileUrl = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: BlockerListConstants.securityGroupId
        )?.appendingPathComponent("BlockList.json", isDirectory: false) else {
            assertionFailure("Unable to get app group container URL")
            return
        }

        let fileContents = """
                           [
                                {
                                    "trigger": {
                                        "url-filter": ".*",
                                        "if-domain": \(namesJson)
                                    },
                                    "action": { "type": "block" }
                                }
                           ]
                           """

        try? fileContents.write(to: fileUrl, atomically: true, encoding: .utf8)
    }
}
