import SwiftUI
import CachedAsyncImage
import BlockaliciousKit

struct DomainRow: View {
    @Binding var domain: BLDomain

    @Environment(BLViewModel.self) private var viewModel

    var body: some View {
        HStack {
            CachedAsyncImage(url: URL(string: domain.favicon)) { image in
                image.resizable()
                    .frame(width: 22, height: 22)
                    .clipShape(.rect(cornerRadius: 4))
                    .accessibilityHidden(true)
            } placeholder: {
                Image(systemName: "questionmark.square.dashed")
                    .resizable()
                    .fontWeight(.light)
                    .frame(width: 22, height: 22)
                    .clipShape(.rect(cornerRadius: 4))
                    .accessibilityHidden(true)
            }
            .accessibilityHidden(true)

            Text(domain.name)

            Spacer()

            Toggle("Active", isOn: $domain.enabled)
                .accessibilityLabel("Toggle \(domain.name)")
                .labelsHidden()
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                viewModel.delete(withID: domain.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
