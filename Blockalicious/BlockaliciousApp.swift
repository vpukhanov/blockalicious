import SwiftUI
import BlockaliciousKit

@main
struct BlockaliciousApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var blockedDomainsVim = BlockedDomainsVim()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 400, minHeight: 300) // Sensible minimum window size
                .environmentObject(blockedDomainsVim)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Domain") {
                    NotificationCenter.default.post(name: .requestAddDomain, object: nil)
                }
                .keyboardShortcut("n")
            }
        }
    }
}
