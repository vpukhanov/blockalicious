import SwiftUI
import CachedAsyncImage

struct ContentView: View {
    @EnvironmentObject private var blockedDomainsVim: BlockedDomainsVim

    @State private var selectedDomain: BlockedDomain.ID?
    @FocusState private var focusedDomain: BlockedDomain.ID?

    var body: some View {
        ZStack {
            Table($blockedDomainsVim.domains, selection: $selectedDomain) {
                TableColumn("🏷️") { $item in
                    CachedAsyncImage(url: URL(string: item.favicon)) { image in
                        image.resizable()
                            .frame(width: 18, height: 18)
                    } placeholder: {
                        Text("🧭")
                    }
                }
                .width(18)
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
                // Command sent from the global menu (File -> New Domain, or Cmd + N)
                .onReceive(NotificationCenter.default.publisher(for: .requestAddDomain)) { _ in add() }
            
            // Invisible button to toggle the activity state of the selected domain
            // via spacebar. Couldn't find a built-in selected item action in the SwiftUI Table
            Button("Toggle Selected Domain", action: toggleSelected)
                .keyboardShortcut(.space, modifiers: [])
                .hidden()

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
    
    private func toggleSelected() {
        if let id = selectedDomain {
            blockedDomainsVim.toggle(withID: id)
        }
    }
}
