//
//  ContentView.swift
//  Blockalicious-iOS
//
//  Created by Vyacheslav Pukhanov on 10.06.2022.
//

import SwiftUI
import CachedAsyncImage
import BlockaliciousKit

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var viewModel: BLViewModel

    @State private var domainField = "*example.com"
    @State private var editMode: EditMode = .inactive
    @State private var selectedIDs = Set<UUID>()

    var body: some View {
        NavigationView {
            List(selection: $selectedIDs) {
                if !viewModel.contentBlockerEnabled {
                    ExtensionDisabledView()
                }

                if !viewModel.groups.isEmpty {
                    Section("Groups") {
                        ForEach(viewModel.groups) { group in
                            GroupRow(group: viewModel.binding(forGroup: group.id))
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        viewModel.delete(withID: group.id)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }

                if !viewModel.ungroupedDomains.isEmpty {
                    Section("Domains") {
                        ForEach(viewModel.ungroupedDomains) { domain in
                            DomainRow(domain: viewModel.binding(forDomain: domain.id))
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        viewModel.delete(withID: domain.id)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            }
            .environment(\.editMode, $editMode)
            .navigationTitle("Blockalicious")
            .toolbar {
                if editMode == .active {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: createGroupFromSelection) {
                            Label("New Group from Selection", systemImage: "folder.badge.plus")
                        }
                        .disabled(!canCreateGroup)
                    }
                }
                
                // EditButton is very buggy for some reason, so I'm using a custom button
                ToolbarItem(placement: .topBarTrailing) {
                    if editMode == .inactive {
                        Button {
                            withAnimation {
                                editMode = .active
                            }
                        } label: {
                            Text("Select")
                        }
                    } else {
                        Button {
                            withAnimation { editMode = .inactive }
                        } label: {
                            Label("Done", systemImage: "checkmark")
                        }
                        .buttonStyle(.glassProminent)
                    }
                }
            }
            .safeAreaBar(edge: .bottom) {
                HStack {
                    TextField("Domain to block", text: $domainField)
                        .onSubmit(add)
                        .padding(12)
                        .glassEffect()
                    
                    Spacer()
                    
                    Button(action: add) {
                        Label("Add", systemImage: "plus")
                    }
                    .buttonBorderShape(.circle)
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)
                }
                .padding()
            }
        }
        .navigationViewStyle(.stack)
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                Task { await viewModel.updateExtensionState() }
            }
        }
    }
    
    private func add() {
        let _ = withAnimation {
            viewModel.add(domain: domainField)
        }
        domainField = "*example.com"
    }

    private var canCreateGroup: Bool {
        viewModel.domains.contains { selectedIDs.contains($0.id) }
    }

    private func createGroupFromSelection() {
        withAnimation {
            let domainIDs = selectedIDs.filter { id in
                viewModel.domains.contains { $0.id == id }
            }
            if domainIDs.isEmpty { return }

            let group = viewModel.addGroup(domainIDs: domainIDs)
            selectedIDs.removeAll()
        }
    }
}

#Preview {
    ContentView()
}
