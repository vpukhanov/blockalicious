import Foundation

class ContentBlockerRequestHandler: NSObject, NSExtensionRequestHandling {
    func beginRequest(with context: NSExtensionContext) {
        guard let attachment = NSItemProvider(contentsOf: FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: BlockerListWriter.securityGroupId
        )?.appendingPathComponent("BlockList.json", isDirectory: false)) else {
            fatalError("Unable to form attachment url.")
        }

        let item = NSExtensionItem()
        item.attachments = [attachment]

        context.completeRequest(returningItems: [item], completionHandler: nil)
    }
}
