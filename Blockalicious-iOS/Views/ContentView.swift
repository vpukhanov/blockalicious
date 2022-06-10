//
//  ContentView.swift
//  Blockalicious-iOS
//
//  Created by Vyacheslav Pukhanov on 10.06.2022.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var blockedDomainsVim: BlockedDomainsVim
    
    @State private var domainField = "*example.com"
    
    var body: some View {
        NavigationView {
            List {
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
                            Text($domain.name.wrappedValue)
                            
                            Spacer()
                            
                            Toggle("Active", isOn: $domain.enabled)
                                .labelsHidden()
                        }
                    }
                    .onDelete(perform: delete)
                }
            }
            .toolbar { EditButton() }
            .navigationTitle("Blockalicious")
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
}
