import Foundation
import SafariServices

class BlockerListWriter {
    #if os(iOS)
    static let contentBlockerBundleId = "ru.pukhanov.Blockalicious-iOS.Content-Blocker-iOS"
    #endif
    #if os(macOS)
    static let contentBlockerBundleId = "ru.pukhanov.Blockalicious.Content-Blocker"
    #endif
    
    static let shared = BlockerListWriter()

    private init() {
    }

    func write(domains: [BlockedDomain]) {
        let names = domains.filter(\.enabled).map { $0.name.lowercased() }
        guard
                let data = try? JSONEncoder().encode(names),
                let namesJson = String(data: data, encoding: .utf8) else {
            fatalError("Unable to json-encode \(names).")
        }
        guard let fileUrl = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: "BFJQQT3YDX.Blockalicious"
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
