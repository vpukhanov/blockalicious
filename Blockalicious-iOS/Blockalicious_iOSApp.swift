//
//  Blockalicious_iOSApp.swift
//  Blockalicious-iOS
//
//  Created by Vyacheslav Pukhanov on 10.06.2022.
//

import SwiftUI

@main
struct Blockalicious_iOSApp: App {
    @StateObject private var blockedDomainsVim = BlockedDomainsVim()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(blockedDomainsVim)
        }
    }
}
