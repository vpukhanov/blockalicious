import SwiftUI
import BlockaliciousKit

struct RenameGroupSheet: View {
    @Binding var group: BLDomainGroup
    @Environment(\.dismiss) private var dismiss

    @State private var groupName: String = ""
    @FocusState private var inputFocus

    var body: some View {
        NavigationView {
            Form {
                TextField("Group Name", text: $groupName)
                    .focused($inputFocus)
                    .onSubmit(save)
            }
            .navigationTitle("Rename Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Label("Cancel", systemImage: "xmark")
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(action: save) {
                        Label("Save", systemImage: "checkmark")
                    }
                    .disabled(groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear {
            groupName = group.name
            inputFocus = true
        }
    }

    private func save() {
        let trimmedName = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty {
            group.name = trimmedName
        }
        dismiss()
    }
}
