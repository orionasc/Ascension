import SwiftUI

struct NodeCreationView: View {
    @EnvironmentObject var progressModel: ArkheionProgressModel
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var archetype: String = "Scholar"
    @State private var type: ArkheionNodeType = .skill
    @State private var prompt: String = ""
    @State private var quote: String = ""
    @State private var status: ArkheionNodeStatus = .dormant

    private let archetypes = ["Scholar", "Sage", "Sovereign"]
    private let quotePool = [
        "Knowledge begins with curiosity.",
        "Seek and you shall find.",
        "Wisdom lights the path forward."
    ]

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
                    Button("Create Node", action: createNode)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(accentColor)
                    Button("Cancel", role: .cancel, action: dismiss.callAsFunction)
                        .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("New Node")
        }
    }

    private func createNode() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty, !trimmedPrompt.isEmpty else { return }

        var finalQuote = quote.trimmingCharacters(in: .whitespacesAndNewlines)
        if finalQuote.isEmpty {
            finalQuote = quotePool.randomElement() ?? ""
        }

        let newNode = ArkheionNode(
            title: trimmedTitle,
            archetype: archetype,
            type: type,
            prompt: trimmedPrompt,
            quote: finalQuote.isEmpty ? nil : finalQuote,
            status: status
        )
        progressModel.addNode(newNode)
        dismiss()
    }
}

#Preview {
    NodeCreationView()
        .environmentObject(ArkheionProgressModel())
}
