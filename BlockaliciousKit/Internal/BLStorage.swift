//
//  DomainStorage.swift
//  Blockalicious
//
//  Created by Вячеслав Пуханов on 08.02.2026.
//

import Foundation
import SafariServices

/// Handles persistent storage
actor BLStorage {
    nonisolated static func loadDomains() -> [BLDomain] {
        // Try loading from app group container
        if let domains = FileManager.default.decode(
            [BLDomain].self,
            from: "Domains.json",
            in: AppConstant.securityGroupId
        ) {
            return domains
        }

        // Fall back to preseed file
        if let domains = Bundle(for: BLStorage.self).decode(
            [BLDomain].self,
            from: "DomainsPreseed.json"
        ) {
            return domains
        }

        return []
    }

    nonisolated static func loadGroups() -> [BLDomainGroup] {
        // Try loading from app group container
        if let groups = FileManager.default.decode(
            [BLDomainGroup].self,
            from: "Groups.json",
            in: AppConstant.securityGroupId
        ) {
            return groups
        }

        return []
    }

    func save(domains: [BLDomain], groups: [BLDomainGroup]) async {
        // Save domains list
        await saveDomainsList(domains)

        // Save groups list
        await saveGroupsList(groups)

        // Generate and save Safari content blocker format
        await writeBlockerList(domains: domains)

        // Reload Safari extension
        try? await SFContentBlockerManager.reloadContentBlocker(withIdentifier: AppConstant.contentBlockerBundleId)
    }

    private func saveDomainsList(_ domains: [BLDomain]) async {
        guard let data = try? JSONEncoder().encode(domains) else {
            assertionFailure("Could not encode blocked domains")
            return
        }

        guard let url = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AppConstant.securityGroupId
        )?.appendingPathComponent("Domains.json", isDirectory: false) else {
            assertionFailure("Could not get app group container URL")
            return
        }

        try? data.write(to: url)
    }

    private func saveGroupsList(_ groups: [BLDomainGroup]) async {
        guard let data = try? JSONEncoder().encode(groups) else {
            assertionFailure("Could not encode groups")
            return
        }

        guard let url = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AppConstant.securityGroupId
        )?.appendingPathComponent("Groups.json", isDirectory: false) else {
            assertionFailure("Could not get app group container URL")
            return
        }

        try? data.write(to: url)
    }

    private func writeBlockerList(domains: [BLDomain]) async {
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
            forSecurityApplicationGroupIdentifier: AppConstant.securityGroupId
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
