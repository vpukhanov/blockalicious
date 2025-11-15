import SwiftUI
import SafariServices

struct ExtensionDisabledView: View {
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                Text("Safari extension is disabled")
                Spacer()
                Button("Go to Safari settings…", action: goToSafariSettings)
                    .buttonStyle(.glassProminent)
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
            .background(Color(nsColor: .controlBackgroundColor))
            .overlay(Divider(), alignment: .top)
        }
    }
    
    private func goToSafariSettings() {
        SFSafariApplication.showPreferencesForExtension(withIdentifier: BlockerListWriter.contentBlockerBundleId)
    }
}
