import SwiftUI
import SafariServices
import BlockaliciousKit

struct ExtensionDisabledView: View {
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                Text("Safari extension is disabled")
                
                Spacer()

                Button("Go to Safari settings…") {
                    Task { await goToSafariSettings() }
                }
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.capsule)
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
            .background(Color(nsColor: .controlBackgroundColor))
            .overlay(Divider(), alignment: .top)
        }
    }
    
    private func goToSafariSettings() async {
        try? await SFSafariApplication.showPreferencesForExtension(withIdentifier: AppConstant.contentBlockerBundleId)
    }
}
