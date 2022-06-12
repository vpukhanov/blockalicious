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
    
    @EnvironmentObject private var blockedDomainsVim: BlockedDomainsVim
    
    @State private var domainField = "*example.com"
    
    var body: some View {
        NavigationView {
            List {
                if !blockedDomainsVim.contentBlockerEnabled {
                    Section {
                        (
                            Text("Safari extension is currently disabled").bold() +
                            Text("\n\nEnable the Blockalicious extension for the blocking rules to take effect.") +
                            Text("\n\nGo to Settings > Safari > Extensions, toggle Blockalicious on")
                        )
                        .padding(.vertical, 6)
                        
                        Button("Go to Settings…", action: goToSafariSettings)
                    }
                }
                
                Section {
                    HStack {
                        domainTextField
                        
                        Spacer()
                        
                        Button(action: add) {
                            Label("Add", systemImage: "plus")
                        }
                    }
                }
                
                Section {
                    ForEach($blockedDomainsVim.domains) { $domain in
                        HStack {
                            if #available(iOS 15.0, *) {
                                CachedAsyncImage(url: URL(string: domain.favicon)) { image in
                                    image.resizable()
                                        .frame(width: 22, height: 22)
                                } placeholder: {
                                    Text("🧭")
                                }
                            }
                            
                            Text($domain.name.wrappedValue)
                            
                            Spacer()
                            
                            Toggle("Active", isOn: $domain.enabled)
                                .labelsHidden()
                        }
                    }
                    .onDelete(perform: delete)
                }
            }
            .navigationTitle("Blockalicious")
            .toolbar { EditButton() }
        }
        .navigationViewStyle(.stack)
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                blockedDomainsVim.updateExtensionState()
            }
        }
    }
    
    private var domainTextField: some View {
        if #available(iOS 15.0, *) {
            return AnyView(
                TextField("Domain to block", text: $domainField)
                    .onSubmit(add)
            )
        } else {
            return AnyView(
                TextField("Domain to block", text: $domainField)
            )
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
