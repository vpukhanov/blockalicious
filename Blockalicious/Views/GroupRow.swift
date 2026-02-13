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
    @Environment(BLViewModel.self) private var viewModel
    
    var body: some View {
        DisclosureGroup {
            ForEach(viewModel.domains(in: group)) { item in
                DomainRow(domain: viewModel.binding(forDomain: item.id), focusedID: $focusedID)
            }
        } label: {
            HStack {
                Image(systemName: "folder")
                    .frame(width: 18, height: 18)
                    .foregroundStyle(.secondary)
                
                TextField("Group Name", text: $group.name)
                    .focused($focusedID, equals: $group.id)
                
                Spacer()
                
                if isMixed {
                    Image(systemName: "diamond.fill")
                        .opacity(0.5)
                        .accessibilityLabel("Some domains disabled")
                }
                
                Toggle("Active", isOn: enabled)
                    .accessibilityLabel("Toggle group \(group.name)")
                    .labelsHidden()
                    .toggleStyle(.switch)
            }
        }
    }
    
    private var enabled: Binding<Bool> {
        Binding(
            get: { viewModel.isGroupEnabled(group) },
            set: { newValue in
                viewModel.toggleGroup(withID: group.id, enabled: newValue)
            }
        )
    }
    
    private var isMixed: Bool {
        viewModel.isGroupEnabled(group) && viewModel.domains(in: group).contains { !$0.enabled }
    }
}
