import SwiftUI
import CachedAsyncImage
import BlockaliciousKit

struct ContentView: View {
    @Environment(BLViewModel.self) private var viewModel
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
            Button("Toggle Selected", action: toggleSelected)
                .keyboardShortcut(.space, modifiers: [])
                .hidden()
        }
        .onDeleteCommand(perform: deleteSelected)
        .toolbar {
            ToolbarItem {
                Button(action: newGroup) {
                    Label("New Group from Selection", systemImage: "folder.badge.plus")
                }
                .keyboardShortcut("n", modifiers: [.command, .control])
                .disabled(isNewGroupDisabled())
            }
            
            ToolbarItem {
                Button(action: newDomain) {
                    Label("New Domain", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !viewModel.contentBlockerEnabled {
                ExtensionDisabledView()
            }
        }
    }

    private func newDomain() {
        let id = viewModel.add()

        // If a group is selected, create the new domain inside the group
        if selectedIDs.count == 1 {
            let selectedID = selectedIDs.first!
            if viewModel.groups.contains(where: { $0.id == selectedID }) {
                viewModel.addDomain(id, toGroup: selectedID)
            }
        }

        focusedID = id
    }
    
    private func newGroup() {
        let domainIDs = selectedIDs.filter { id in
            viewModel.domains.contains(where: { $0.id == id })
        }
        if !domainIDs.isEmpty {
            selectedIDs.removeAll()
            focusedID = viewModel.addGroup(domainIDs: domainIDs)
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
