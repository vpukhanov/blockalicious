//
//  GroupRow.swift
//  Blockalicious
//
//  Created by Вячеслав Пуханов on 08.02.2026.
//

import SwiftUI
import BlockaliciousKit

struct GroupRow: View {
    @Binding var group: BLDomainGroup
    @FocusState.Binding var focusedID: UUID?
    
    @EnvironmentObject private var viewModel: BLViewModel
    
    var body: some View {
        DisclosureGroup {
            ForEach(viewModel.domains(in: group)) { item in
                DomainRow(domain: viewModel.binding(forDomain: item.id), focusedID: $focusedID)
            }
        } label: {
            Text(group.name)
        }
    }
}
