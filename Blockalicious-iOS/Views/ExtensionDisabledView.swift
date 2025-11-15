//
//  ExtensionDisabledView.swift
//  Blockalicious-iOS
//
//  Created by Вячеслав Пуханов on 15.11.2025.
//

import SwiftUI

struct ExtensionDisabledView: View {
    @Environment(\.openURL) var openURL

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text("\(Image(systemName: "exclamationmark.triangle.fill")) Safari extension is currently disabled").bold()
                Text("Enable the Blockalicious extension for the blocking rules to take effect")
                Text("Go to Settings \(Image(systemName: "arrow.right")) Apps \(Image(systemName: "arrow.right")) Safari \(Image(systemName: "arrow.right")) Extensions and toggle Blockalicious on")
            }

            Button(action: goToSafariSettings) {
                Label("Go to Settings…", systemImage: "gear")
            }
        }
    }
    
    private func goToSafariSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
    }
}

#Preview {
    ExtensionDisabledView()
}
