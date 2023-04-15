import Foundation
import SafariServices

class BlockerListWriter {
    #if os(iOS)
    static let contentBlockerBundleId = "ru.pukhanov.Blockalicious.Content-Blocker-iOS"
    static let securityGroupId = "group.BFJQQT3YDX.Blockalicious"
    #endif
    #if os(macOS)
    static let contentBlockerBundleId = "ru.pukhanov.Blockalicious.Content-Blocker"
    static let securityGroupId = "BFJQQT3YDX.Blockalicious"
    #endif
    
    static let shared = BlockerListWriter()

    private init() {
    }

    func write(domains: [BlockedDomain]) {
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
                let namesJson = String(data: data, encoding: .utf8) else {
            fatalError("Unable to json-encode \(names).")
        }
        guard let fileUrl = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: BlockerListWriter.securityGroupId
        )?.appendingPathComponent("BlockList.json", isDirectory: false) else {
            fatalError("Unable to get app group container url.")
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
        try? fileContents.write(to: fileUrl, atomically: false, encoding: .utf8)

        SFContentBlockerManager.reloadContentBlocker(withIdentifier: BlockerListWriter.contentBlockerBundleId)
    }
}
