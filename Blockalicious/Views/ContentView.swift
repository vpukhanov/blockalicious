import SwiftUI
import CachedAsyncImage
import BlockaliciousKit

struct ContentView: View {
    @EnvironmentObject private var viewModel: BLViewModel

    @State private var selectedIDs = Set<BLDomain.ID>()
    @FocusState private var focusedDomain: BLDomain.ID?

    var body: some View {
        ZStack {
            List(selection: $selectedIDs) {
                ForEach($viewModel.domains) { $item in
                    DomainRow(domain: $item, focusedDomain: $focusedDomain)
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

            if !viewModel.contentBlockerEnabled {
                ExtensionDisabledView()
            }
        }
    }

    private func add() {
        focusedDomain = viewModel.add()
    }

    private func deleteSelected() {
        selectedIDs.forEach(viewModel.delete(withID:))
    }
    
    private func toggleSelected() {
        selectedIDs.forEach(viewModel.toggle(withID:))
    }
}
