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
    @Environment(BLViewModel.self) private var viewModel
    @State private var domainField = ""
    @State private var editMode: EditMode = .inactive
    @State private var selectedIDs = Set<UUID>()
    @State private var groupToRename: BLDomainGroup?

    var body: some View {
        NavigationStack {
            List(selection: $selectedIDs) {
                if !viewModel.contentBlockerEnabled {
                    ExtensionDisabledView()
                }

                if !viewModel.groups.isEmpty {
                    Section("Groups") {
                        ForEach(viewModel.groups) { group in
                            GroupRow(group: viewModel.binding(forGroup: group.id))
                        }
                    }
                }

                if !viewModel.ungroupedDomains.isEmpty {
                    Section("Domains") {
                        ForEach(viewModel.ungroupedDomains) { domain in
                            DomainRow(domain: viewModel.binding(forDomain: domain.id))
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
                    TextField("Domain to block", text: $domainField, prompt: Text("Enter domain name"))
                        .textContentType(.URL)
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
        .sheet(item: $groupToRename) { group in
            RenameGroupSheet(group: viewModel.binding(forGroup: group.id))
                .presentationDetents([.medium, .large])
        }
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
        domainField = ""
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

            let id = viewModel.addGroup(domainIDs: domainIDs)
            selectedIDs.removeAll()
            
            groupToRename = viewModel.groups.first { $0.id == id }
        }
    }
}
