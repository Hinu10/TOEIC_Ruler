import SwiftUI

struct MaterialsPage: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var editingDraft: MaterialFormDraft?
    @State private var validationMessage: String?

    var body: some View {
        List {
            if store.appData.materials.isEmpty {
                ContentUnavailableView(
                    "教材が未登録です",
                    systemImage: "books.vertical",
                    description: Text("参考書、問題集、単語帳などを登録してください。")
                )
            } else {
                Section {
                    ForEach(store.appData.materials) { material in
                        MaterialCard(material: material) {
                            editingDraft = MaterialFormDraft(material: material)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                delete(material)
                            } label: {
                                Label("削除", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("教材")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    editingDraft = MaterialFormDraft()
                } label: {
                    Label("追加", systemImage: "plus")
                }
            }
        }
        .sheet(item: $editingDraft) { draft in
            NavigationStack {
                MaterialFormPage(
                    draft: draft,
                    validationMessage: $validationMessage,
                    onCancel: {
                        editingDraft = nil
                        validationMessage = nil
                    },
                    onSave: { savedDraft in
                        save(savedDraft)
                    }
                )
            }
        }
    }

    private func save(_ draft: MaterialFormDraft) {
        validationMessage = draft.validationMessage
        guard validationMessage == nil else { return }

        do {
            try store.saveMaterial(draft.makeMaterial())
            editingDraft = nil
            validationMessage = nil
        } catch {
            validationMessage = "保存に失敗しました"
        }
    }

    private func delete(_ material: Material) {
        try? store.deleteMaterial(material)
    }
}

struct MaterialFormPage: View {
    @State var draft: MaterialFormDraft
    @Binding var validationMessage: String?
    let onCancel: () -> Void
    let onSave: (MaterialFormDraft) -> Void

    var body: some View {
        Form {
            MaterialForm(draft: $draft)

            if let validationMessage {
                Section {
                    Label(validationMessage, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(draft.isNew ? "教材登録" : "教材編集")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("キャンセル", action: onCancel)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    onSave(draft)
                }
            }
        }
    }
}

struct MaterialForm: View {
    @Binding var draft: MaterialFormDraft

    var body: some View {
        let selection = Binding<String>(
            get: { draft.templateID ?? MaterialFormDraft.customTemplateID },
            set: { selection in
                var nextDraft = draft
                nextDraft.applyTemplateSelection(selection)
                draft = nextDraft
            }
        )

        Section("基本情報") {
            Picker("教材", selection: selection) {
                ForEach(MaterialTemplate.selectableTemplates) { template in
                    Text(template.name).tag(template.id)
                }
                Text("その他").tag(MaterialFormDraft.customTemplateID)
            }

            if draft.templateID == MaterialTemplate.goldenPhrase.id {
                LabeledContent("出版社", value: draft.publisher)
                LabeledContent("著者", value: draft.author)
                LabeledContent("対象レベル", value: draft.targetLevel)
                LabeledContent("単語数", value: "\(draft.itemCount)")
            } else {
                TextField("教材名", text: $draft.name)
                Picker("教材種別", selection: $draft.type) {
                    ForEach(MaterialType.allCases) { type in
                        Text(type.title).tag(type)
                    }
                }
                TextField("出版社", text: $draft.publisher)
                TextField("著者", text: $draft.author)
                TextField("対象レベル", text: $draft.targetLevel)
                Stepper("問題数または単語数 \(draft.itemCount)", value: $draft.itemCount, in: 0...9999)
            }
        }

        Section("教材情報") {
            TextField("セクション / Chapter 情報", text: $draft.sectionInfo, axis: .vertical)
                .lineLimit(2...5)
            TextField("学習記録に必要な識別情報", text: $draft.learningIdentifier, axis: .vertical)
                .lineLimit(2...4)
        }

        Section("対象Part") {
            if draft.templateID == MaterialTemplate.goldenPhrase.id {
                Text(draft.targetParts.sorted { $0.number < $1.number }.map(\.title).joined(separator: ", "))
                    .foregroundStyle(.secondary)
            } else {
                PartSelector(selection: $draft.targetParts)
            }
        }

        Section("進捗") {
            Stepper("現在周回数 \(draft.currentRound)", value: $draft.currentRound, in: 0...99)
            Stepper("目標周回数 \(draft.targetRounds)", value: $draft.targetRounds, in: 1...99)
            VStack(alignment: .leading) {
                HStack {
                    Text("進捗率")
                    Spacer()
                    Text("\(Int(draft.progressRate))%")
                        .foregroundStyle(.secondary)
                }
                Slider(value: $draft.progressRate, in: 0...100, step: 5)
            }
            TextField("メモ", text: $draft.memo, axis: .vertical)
                .lineLimit(3...6)
        }
    }
}

struct MaterialCard: View {
    let material: Material
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(material.name)
                        .font(.headline)
                    Text(material.type.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: onEdit) {
                    Label("編集", systemImage: "pencil")
                }
                .buttonStyle(.borderless)
            }

            ProgressBar(value: material.progressRate / 100)

            HStack {
                Label("\(material.currentRound)/\(material.targetRounds)周", systemImage: "arrow.triangle.2.circlepath")
                Spacer()
                Text("\(Int(material.progressRate))%")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Text(material.targetParts.sorted { $0.number < $1.number }.map(\.title).joined(separator: ", "))
                .font(.caption)
                .foregroundStyle(.secondary)

            if let memo = material.memo, !memo.isEmpty {
                Text(memo)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let publisher = material.publisher, !publisher.isEmpty {
                Text([publisher, material.author].compactMap { $0 }.joined(separator: " / "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}

struct ProgressBar: View {
    let value: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.gray.opacity(0.2))
                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: proxy.size.width * min(max(value, 0), 1))
            }
        }
        .frame(height: 8)
    }
}

struct MaterialFormDraft: Identifiable {
    static let customTemplateID = "custom"

    var id: UUID
    var templateID: String?
    var name: String
    var type: MaterialType
    var publisher: String
    var author: String
    var targetLevel: String
    var sectionInfo: String
    var itemCount: Int
    var learningIdentifier: String
    var targetParts: Set<TOEICPart>
    var currentRound: Int
    var targetRounds: Int
    var progressRate: Double
    var memo: String
    var createdAt: Date

    var isNew: Bool { createdAt.timeIntervalSinceNow > -5 }

    init() {
        id = UUID()
        templateID = nil
        name = ""
        type = .officialBook
        publisher = ""
        author = ""
        targetLevel = ""
        sectionInfo = ""
        itemCount = 0
        learningIdentifier = ""
        targetParts = []
        currentRound = 0
        targetRounds = 3
        progressRate = 0
        memo = ""
        createdAt = Date()
        applyTemplateSelection(MaterialTemplate.goldenPhrase.id)
    }

    init(material: Material) {
        id = material.id
        templateID = material.templateID
        name = material.name
        type = material.type
        publisher = material.publisher ?? ""
        author = material.author ?? ""
        targetLevel = material.targetLevel ?? ""
        sectionInfo = material.sectionInfo ?? ""
        itemCount = material.itemCount ?? 0
        learningIdentifier = material.learningIdentifier ?? ""
        targetParts = Set(material.targetParts)
        currentRound = material.currentRound
        targetRounds = material.targetRounds
        progressRate = material.progressRate
        memo = material.memo ?? ""
        createdAt = material.createdAt
    }

    var validationMessage: String? {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "教材名を入力してください"
        }
        if targetParts.isEmpty {
            return "対象Partを1つ以上選択してください"
        }
        if currentRound > targetRounds {
            return "現在周回数は目標周回数以下にしてください"
        }
        return nil
    }

    mutating func applyTemplateSelection(_ selection: String) {
        guard selection != Self.customTemplateID else {
            templateID = nil
            return
        }
        guard let template = MaterialTemplate.selectableTemplates.first(where: { $0.id == selection }) else {
            return
        }
        templateID = template.id
        name = template.name
        type = template.type
        publisher = template.publisher
        author = template.author
        targetLevel = template.targetLevel
        sectionInfo = template.sectionInfo
        itemCount = template.itemCount
        learningIdentifier = template.learningIdentifier
        targetParts = Set(template.targetParts)
        targetRounds = template.targetRounds
    }

    private func cleaned(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    func makeMaterial() -> Material {
        let now = Date()
        return Material(
            id: id,
            templateID: templateID,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            type: type,
            publisher: cleaned(publisher),
            author: cleaned(author),
            targetLevel: cleaned(targetLevel),
            sectionInfo: cleaned(sectionInfo),
            itemCount: itemCount > 0 ? itemCount : nil,
            learningIdentifier: cleaned(learningIdentifier),
            targetParts: targetParts.sorted { $0.number < $1.number },
            currentRound: currentRound,
            targetRounds: targetRounds,
            progressRate: progressRate,
            memo: memo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : memo.trimmingCharacters(in: .whitespacesAndNewlines),
            createdAt: createdAt,
            updatedAt: now
        )
    }
}
