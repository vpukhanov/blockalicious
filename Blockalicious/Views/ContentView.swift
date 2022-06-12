import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var blockedDomainsVim: BlockedDomainsVim

    @State private var selectedDomain: BlockedDomain.ID?
    @FocusState private var focusedDomain: BlockedDomain.ID?

    var body: some View {
        ZStack {
            Table($blockedDomainsVim.domains, selection: $selectedDomain) {
                TableColumn("🏷️") { $item in
                    AsyncImage(url: URL(string: item.favicon)) { image in
                        image.resizable()
                            .frame(width: 16, height: 16)
                    } placeholder: {
                        Text("🧭")
                    }
                }
                .width(16)
                TableColumn("Domain") { $item in
                    TextField("Domain Name", text: $item.name)
                        .textCase(.lowercase)
                        .focused($focusedDomain, equals: $item.id)
                }
                TableColumn("Active") { $item in
                    Toggle("Active", isOn: $item.enabled)
                        .labelsHidden()
                }
            }
                .onDeleteCommand(perform: deleteSelected)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: add) {
                            Label("Add Domain", systemImage: "plus")
                        }
                    }
                }

            if !blockedDomainsVim.contentBlockerEnabled {
                ExtensionDisabledView()
            }
        }
    }

    private func add() {
        focusedDomain = blockedDomainsVim.add()
    }

    private func deleteSelected() {
        if let id = selectedDomain {
            blockedDomainsVim.delete(withID: id)
        }
    }
}
