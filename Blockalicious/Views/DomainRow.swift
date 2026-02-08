//
//  DomainRow.swift
//  Blockalicious
//
//  Created by Вячеслав Пуханов on 08.02.2026.
//

import SwiftUI
import CachedAsyncImage
import BlockaliciousKit

struct DomainRow: View {
    @Binding var domain: BLDomain
    @FocusState.Binding var focusedID: UUID?
    
    var body: some View {
        HStack {
            CachedAsyncImage(url: URL(string: domain.favicon)) { image in
                image.resizable()
                    .frame(width: 18, height: 18)
                    .clipShape(.rect(cornerRadius: 4))
            } placeholder: {
                Image(systemName: "questionmark.square.dashed")
                    .resizable()
                    .fontWeight(.light)
                    .frame(width: 18, height: 18)
                    .clipShape(.rect(cornerRadius: 4))
            }
            
            TextField("Domain Name", text: $domain.name)
                .textCase(.lowercase)
                .focused($focusedID, equals: $domain.id)
            
            Spacer()
            
            Toggle("Active", isOn: $domain.enabled)
                .labelsHidden()
                .toggleStyle(.switch)
        }
    }
}
