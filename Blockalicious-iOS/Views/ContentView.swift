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
    
    @StateObject private var viewModel = BLViewModel()
    
    @State private var domainField = "*example.com"
    
    var body: some View {
        NavigationView {
            List {
                if !viewModel.contentBlockerEnabled {
                    ExtensionDisabledView()
                }
                
                Section {
                    ForEach($viewModel.domains) { $domain in
                        HStack {
                            CachedAsyncImage(url: URL(string: domain.favicon)) { image in
                                image.resizable()
                                    .frame(width: 22, height: 22)
                                    .clipShape(.rect(cornerRadius: 4))
                            } placeholder: {
                                Image(systemName: "questionmark.square.dashed")
                                    .resizable()
                                    .fontWeight(.light)
                                    .frame(width: 22, height: 22)
                                    .clipShape(.rect(cornerRadius: 4))
                            }
                            
                            Text(domain.name)
                            
                            Spacer()
                            
                            Toggle("Active", isOn: $domain.enabled)
                                .labelsHidden()
                        }
                    }
                    .onDelete(perform: delete)
                }
            }
            .navigationTitle("Blockalicious")
            .toolbar {
                EditButton()
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
    
    private func delete(_ indexSet: IndexSet) {
        for index in indexSet {
            let domain = viewModel.domains[index]
            viewModel.delete(withID: domain.id)
        }
    }
}

#Preview {
    ContentView()
}
