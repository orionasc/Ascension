import SwiftUI

struct NodeEditView: View {
    @EnvironmentObject var progressModel: ArkheionProgressModel
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var archetype: String
    @State private var type: ArkheionNodeType
    @State private var prompt: String
    @State private var quote: String
    @State private var status: ArkheionNodeStatus

    private let nodeID: UUID
    private let archetypes = ["Scholar", "Sage", "Sovereign"]

    init(node: ArkheionNode) {
        _title = State(initialValue: node.title)
        _archetype = State(initialValue: node.archetype)
        _type = State(initialValue: node.type)
        _prompt = State(initialValue: node.prompt)
        _quote = State(initialValue: node.quote ?? "")
        _status = State(initialValue: node.status)
        nodeID = node.id
    }

    private var accentColor: Color {
        switch archetype {
        case "Scholar": return .blue
        case "Sage": return Color(red: 0.83, green: 0.67, blue: 0.22)
        case "Sovereign": return Color(red: 0.80, green: 0.34, blue: 0.08)
        default: return .accentColor
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading) {
                        Text(title.isEmpty ? "Node Preview" : title)
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(RoundedRectangle(cornerRadius: 12).fill(accentColor.opacity(0.8)))
                    }
                }
                Section("Info") {
                    TextField("Title", text: $title)
                    Picker("Archetype", selection: $archetype) {
                        ForEach(archetypes, id: \.self) { Text($0) }
                    }
                    Picker("Type", selection: $type) {
                        ForEach(ArkheionNodeType.allCases, id: \.self) { Text($0.rawValue) }
                    }
                    Picker("Status", selection: $status) {
                        ForEach(ArkheionNodeStatus.allCases, id: \.self) { Text($0.rawValue) }
                    }
                }
                Section("Prompt") {
                    TextEditor(text: $prompt)
                        .frame(minHeight: 80)
                }
                Section("Quote (Optional)") {
                    TextEditor(text: $quote)
                        .frame(minHeight: 60)
                }
                Section {
                    Button("Save Changes", action: saveChanges)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(accentColor)
                    Button("Cancel", role: .cancel, action: dismiss.callAsFunction)
                        .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Edit Node")
        }
    }

    private func saveChanges() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty, !trimmedPrompt.isEmpty else { return }
        let trimmedQuote = quote.trimmingCharacters(in: .whitespacesAndNewlines)
        let updated = ArkheionNode(id: nodeID, title: trimmedTitle, archetype: archetype, type: type, prompt: trimmedPrompt, quote: trimmedQuote.isEmpty ? nil : trimmedQuote, status: status)
        progressModel.updateNode(updated)
        Task { await progressModel.save() }
        dismiss()
    }
}

#Preview {
    NodeEditView(node: ArkheionNode(title: "Test", archetype: "Scholar", type: .skill, prompt: "P", quote: nil))
        .environmentObject(ArkheionProgressModel())
}
