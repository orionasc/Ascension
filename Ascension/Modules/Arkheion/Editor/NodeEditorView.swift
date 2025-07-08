import SwiftUI

/// Editor allowing modification of node details
struct NodeEditorView: View {
    @Binding var node: Node
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $node.title)
                    TextField("Description", text: $node.description)
                }

                Section("Type") {
                    Picker("Type", selection: $node.type) {
                        ForEach(NodeType.allCases) { type in
                            Text(type.rawValue.capitalized).tag(type)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                Section("Attribute") {
                    Picker("Attribute", selection: $node.attribute) {
                        ForEach(NodeAttribute.allCases) { attr in
                            Text(attr.rawValue.capitalized).tag(attr)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                Section("Size") {
                    Picker("Size", selection: $node.size) {
                        ForEach(NodeSize.allCases) { size in
                            Text(size.rawValue.capitalized).tag(size)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Toggle("Completed", isOn: $node.completed)
            }
            .navigationTitle("Edit Node")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    NodeEditorView(node: .constant(Node()))
}
