//
//  ContentView.swift
//  Blockalicious-iOS
//
//  Created by Vyacheslav Pukhanov on 10.06.2022.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var blockedDomainsVim: BlockedDomainsVim
    
    var body: some View {
        NavigationView {
            List {
                ForEach(blockedDomainsVim.domains) { domain in
                    Text(domain.name)
                }
            }
            .navigationTitle("Blocklist")
        }
    }
}
