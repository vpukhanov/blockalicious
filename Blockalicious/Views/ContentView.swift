import SwiftUI
import CachedAsyncImage
import BlockaliciousKit

struct ContentView: View {
    @EnvironmentObject private var viewModel: BLViewModel

    @State private var selectedIDs = Set<UUID>()
    @FocusState private var focusedID: UUID?

    var body: some View {
        ZStack {
            List(selection: $selectedIDs) {
                ForEach(viewModel.groups) { group in
                    GroupRow(group: viewModel.binding(forGroup: group.id), focusedID: $focusedID)
                }
                ForEach(viewModel.ungroupedDomains) { item in
                    DomainRow(domain: viewModel.binding(forDomain: item.id), focusedID: $focusedID)
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
            
            // Invisible button to toggle the activity state of the selected domain
            // via spacebar. Couldn't find a built-in selected item action in the SwiftUI Table
            Button("Toggle Selected Domain", action: toggleSelected)
                .keyboardShortcut(.space, modifiers: [])
                .hidden()

            if !viewModel.contentBlockerEnabled {
                ExtensionDisabledView()
            }
        }
        .onDeleteCommand(perform: deleteSelected)
        .toolbar {
            ToolbarItem {
                Button(action: newGroup) {
                    Label("New Group", systemImage: "folder.badge.plus")
                }
                .disabled(isNewGroupDisabled())
            }
            
            ToolbarItem {
                Button(action: newDomain) {
                    Label("New Domain", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
    }

    private func newDomain() {
        focusedID = viewModel.add()
    }
    
    private func newGroup() {
        let domainIDs = selectedIDs.filter { id in
            viewModel.domains.contains(where: { $0.id == id })
        }
        if !domainIDs.isEmpty {
            viewModel.addGroup(domainIDs: domainIDs)
        }
    }

    private func deleteSelected() {
        selectedIDs.forEach(viewModel.delete(withID:))
    }
    
    private func toggleSelected() {
        selectedIDs.forEach(viewModel.toggle(withID:))
    }
    
    /// If no domains are selected, disable the New Group button
    private func isNewGroupDisabled() -> Bool {
        viewModel.domains.allSatisfy { domain in
            !selectedIDs.contains(domain.id)
        }
    }
}
