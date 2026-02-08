import SwiftUI
import BlockaliciousKit

@main
struct BlockaliciousApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var viewModel = BLViewModel()

    var body: some Scene {
        Window("Blockalicious", id: "main") {
            ContentView()
                .frame(minWidth: 400, minHeight: 300) // Sensible minimum window size
                .environmentObject(viewModel)
        }
        .defaultSize(width: 400, height: 300)
    }
}
