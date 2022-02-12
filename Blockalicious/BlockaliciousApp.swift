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
    }
}
