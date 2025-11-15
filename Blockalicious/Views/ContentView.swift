import SwiftUI
import CachedAsyncImage

struct ContentView: View {
    @EnvironmentObject private var blockedDomainsVim: BlockedDomainsVim

    @State private var selectedDomain: BlockedDomain.ID?
    @FocusState private var focusedDomain: BlockedDomain.ID?

    var body: some View {
        ZStack {
            List($blockedDomainsVim.domains, selection: $selectedDomain) { $item in
                HStack {
                    CachedAsyncImage(url: URL(string: item.favicon)) { image in
                        image.resizable()
                            .frame(width: 18, height: 18)
                            .clipShape(.rect(cornerRadius: 4))
                    } placeholder: {
                        Image(systemName: "questionmark.square.dashed")
                            .resizable()
                            .fontWeight(.light)
                            .frame(width: 18, height: 18)
                            .clipShape(.rect(cornerRadius: 4))
                    }
                    
                    TextField("Domain Name", text: $item.name)
                        .textCase(.lowercase)
                        .focused($focusedDomain, equals: $item.id)
                    
                    Spacer()
                    
                    Toggle("Active", isOn: $item.enabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
            .onDeleteCommand(perform: deleteSelected)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: add) {
                        Label("Add Domain", systemImage: "plus")
                    }
                }
            }
            // File -> New Domain, or Cmd + N
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
