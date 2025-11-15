//
//  ContentView.swift
//  Blockalicious-iOS
//
//  Created by Vyacheslav Pukhanov on 10.06.2022.
//

import SwiftUI
import CachedAsyncImage

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    
    @StateObject private var blockedDomainsVim = BlockedDomainsVim()
    
    @State private var domainField = "*example.com"
    
    var body: some View {
        NavigationView {
            List {
                if !blockedDomainsVim.contentBlockerEnabled {
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("\(Image(systemName: "exclamationmark.triangle.fill")) Safari extension is currently disabled").bold()
                            Text("Enable the Blockalicious extension for the blocking rules to take effect")
                            Text("Go to Settings > Apps > Safari > Extensions and toggle Blockalicious on")
                        }

                        Button(action: goToSafariSettings) {
                            Label("Go to Settings…", systemImage: "gear")
                        }
                    }
                }
                
                Section {
                    ForEach($blockedDomainsVim.domains) { $domain in
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
                    
                    Spacer()
                    
                    Button(action: add) {
                        Label("Add", systemImage: "plus")
                    }
                    .buttonStyle(.bordered)
                    .tint(.accent)
                }
                .padding()
                .glassEffect()
                .padding()
            }
        }
        .navigationViewStyle(.stack)
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                blockedDomainsVim.updateExtensionState()
            }
        }
    }
    
    private func add() {
        let _ = withAnimation {
            blockedDomainsVim.add(domain: domainField)
        }
        domainField = "*example.com"
    }
    
    private func delete(_ indexSet: IndexSet) {
        for index in indexSet {
            let domain = blockedDomainsVim.domains[index]
            blockedDomainsVim.delete(withID: domain.id)
        }
    }

    private func goToSafariSettings() {
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
    }
}

#Preview {
    ContentView()
}
