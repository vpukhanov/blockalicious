import SwiftUI
import SafariServices

struct ExtensionDisabledView: View {
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Text("Safari extension is disabled")
                Spacer()
                Button("Go to Safari settings…", action: goToSafariSettings)
            }
                .padding(.horizontal)
                .padding(.vertical, 4)
                .background(Color(nsColor: .controlBackgroundColor))
                .overlay(Divider(), alignment: .top)
        }
    }
    
    private func goToSafariSettings() {
        SFSafariApplication.showPreferencesForExtension(withIdentifier: "ru.pukhanov.Blockalicious.Content-Blocker")
    }
}
