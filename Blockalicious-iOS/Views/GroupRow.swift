import SwiftUI
import BlockaliciousKit

struct GroupRow: View {
    @Binding var group: BLDomainGroup

    @Environment(BLViewModel.self) private var viewModel

    var body: some View {
        DisclosureGroup {
            ForEach(viewModel.domains(in: group)) { domain in
                DomainRow(domain: viewModel.binding(forDomain: domain.id))
                    .selectionDisabled(false)
            }
        } label: {
            HStack {
                Image(systemName: "folder")
                    .frame(width: 22, height: 22)
                    .foregroundStyle(.secondary)

                Text(group.name)

                Spacer()

                if isMixed {
                    Image(systemName: "diamond.fill")
                        .opacity(0.3)
                        .accessibilityHidden(true)
                }

                Toggle("Active", isOn: enabled)
                    .labelsHidden()
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    viewModel.delete(withID: group.id)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .selectionDisabled()
    }

    private var enabled: Binding<Bool> {
        Binding(
            get: { viewModel.isGroupEnabled(group) },
            set: { newValue in
                viewModel.toggleGroup(withID: group.id, enabled: newValue)
            }
        )
    }

    private var isMixed: Bool {
        viewModel.isGroupEnabled(group) && viewModel.domains(in: group).contains { !$0.enabled }
    }
}
