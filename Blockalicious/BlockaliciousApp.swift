import SwiftUI

@main
struct BlockaliciousApp: App {
    @StateObject private var blockedDomainsVim = BlockedDomainsVim()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 400, minHeight: 200) // Specify sensible minimum window size
                .environmentObject(blockedDomainsVim)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Domain") {
                    NotificationCenter.default.post(name: .requestAddDomain, object: nil)
                }
                .keyboardShortcut("n")
                Button("Toggle All Domains") {
                    NotificationCenter.default.post(name: .requestToggleAllDomains, object: nil)
                }
                .keyboardShortcut("t", modifiers: [.command, .shift])
            }
        }
    }
}
