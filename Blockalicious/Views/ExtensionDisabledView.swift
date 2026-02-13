import SwiftUI
import SafariServices
import BlockaliciousKit

struct ExtensionDisabledView: View {
    var body: some View {
        HStack {
            Label("Safari extension is disabled", systemImage: "exclamationmark.triangle.fill")
            
            Spacer()

            Button("Go to Safari settings…") {
                Task { await goToSafariSettings() }
            }
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.capsule)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .background(.bar)
        .overlay(Divider(), alignment: .top)
    }
    
    private func goToSafariSettings() async {
        try? await SFSafariApplication.showPreferencesForExtension(withIdentifier: AppConstant.contentBlockerBundleId)
    }
}
