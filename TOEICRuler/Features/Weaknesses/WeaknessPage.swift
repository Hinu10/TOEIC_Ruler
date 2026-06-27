import SwiftUI

struct MistakeReasonItem: Identifiable, Equatable {
    var id: EntityID
    var studyLog: StudyLog
    var storedReason: MistakeReason?
    var text: String
    var keywordTags: [String]
    var manualTags: [String]

    var part: TOEICPart { studyLog.part }
}

func classifyMistakeReason(_ text: String) -> [String] {
    let lowercased = text.lowercased()
    var tags: [String] = []

    if lowercased.contains("単語") || lowercased.contains("語彙") || lowercased.contains("word") {
        tags.append("語彙")
    }
    if lowercased.contains("文法") || lowercased.contains("時制") || lowercased.contains("品詞") || lowercased.contains("grammar") {
        tags.append("文法")
    }
    if lowercased.contains("聞") || lowercased.contains("音") || lowercased.contains("リスニング") || lowercased.contains("listen") {
        tags.append("聞き取り")
    }
    if lowercased.contains("時間") || lowercased.contains("遅") || lowercased.contains("速") || lowercased.contains("speed") {
        tags.append("時間配分")
    }
    if lowercased.contains("ケアレス") || lowercased.contains("見落") || lowercased.contains("読み間違") {
        tags.append("ケアレス")
    }

    return tags.isEmpty ? ["未分類"] : tags
}

struct WeaknessPage: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var selectedPart: TOEICPart?
    @State private var editingItem: MistakeReasonItem?
    @State private var validationMessage: String?

    private var mistakeItems: [MistakeReasonItem] {
        store.appData.studyLogs
            .filter { !($0.mistakeReasonText ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .sorted { $0.studiedOn > $1.studiedOn }
            .map { studyLog in
                let stored = store.appData.mistakeReasons.first { $0.studyLogID == studyLog.id }
                let text = studyLog.mistakeReasonText ?? ""
                return MistakeReasonItem(
                    id: stored?.id ?? studyLog.id,
                    studyLog: studyLog,
                    storedReason: stored,
                    text: stored?.text.isEmpty == false ? stored?.text ?? text : text,
                    keywordTags: classifyMistakeReason(text),
                    manualTags: stored?.manualTags ?? []
                )
            }
    }

    private var filteredItems: [MistakeReasonItem] {
        guard let selectedPart else { return mistakeItems }
        return mistakeItems.filter { $0.part == selectedPart }
    }

    var body: some View {
        List {
            Section {
                PartFilter(selection: $selectedPart)
            }

            if filteredItems.isEmpty {
                ContentUnavailableView(
                    "ミス理由がありません",
                    systemImage: "target",
                    description: Text("学習記録にミス理由を保存すると、Part別に確認できます。")
                )
            } else {
                MistakeReasonList(items: filteredItems) { item in
                    editingItem = item
                }
            }
        }
        .navigationTitle("弱点管理")
        .sheet(item: $editingItem) { item in
            NavigationStack {
                TagEditor(
                    item: item,
                    validationMessage: $validationMessage,
                    onCancel: {
                        editingItem = nil
                        validationMessage = nil
                    },
                    onSave: saveTags
                )
            }
        }
    }

    private func saveTags(_ item: MistakeReasonItem, tags: [String]) {
        let cleanedTags = tags
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let now = Date()
        let reason = MistakeReason(
            id: item.storedReason?.id ?? UUID(),
            studyLogID: item.studyLog.id,
            part: item.studyLog.part,
            text: item.text,
            manualTags: cleanedTags,
            keywordTags: item.keywordTags,
            classificationType: cleanedTags.isEmpty ? .keyword : .manual,
            category: category(for: item.keywordTags),
            title: item.text,
            detail: item.text,
            createdAt: item.storedReason?.createdAt ?? now,
            updatedAt: now
        )

        do {
            try store.saveMistakeReason(reason)
            editingItem = nil
            validationMessage = nil
        } catch {
            validationMessage = "保存に失敗しました"
        }
    }

    private func category(for tags: [String]) -> MistakeReasonCategory {
        if tags.contains("語彙") { return .vocabulary }
        if tags.contains("文法") { return .grammar }
        if tags.contains("聞き取り") { return .listening }
        if tags.contains("時間配分") { return .speed }
        if tags.contains("ケアレス") { return .careless }
        return .other
    }
}

struct MistakeReasonList: View {
    let items: [MistakeReasonItem]
    let onEditTags: (MistakeReasonItem) -> Void

    var body: some View {
        Section("ミス理由") {
            ForEach(items) { item in
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(item.part.title)
                            .font(.headline)
                        Spacer()
                        Text(item.studyLog.studiedOn.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text(item.text)
                        .font(.body)

                    TagRow(title: "分類", tags: item.keywordTags)
                    TagRow(title: "手動", tags: item.manualTags.isEmpty ? ["未設定"] : item.manualTags)

                    Button {
                        onEditTags(item)
                    } label: {
                        Label("タグ編集", systemImage: "tag")
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.vertical, 6)
            }
        }
    }
}

struct PartFilter: View {
    @Binding var selection: TOEICPart?

    var body: some View {
        Picker("Part", selection: $selection) {
            Text("すべて").tag(nil as TOEICPart?)
            ForEach(TOEICPart.allCases) { part in
                Text(part.title).tag(Optional(part))
            }
        }
        .pickerStyle(.segmented)
    }
}

struct TagEditor: View {
    let item: MistakeReasonItem
    @Binding var validationMessage: String?
    let onCancel: () -> Void
    let onSave: (MistakeReasonItem, [String]) -> Void
    @State private var tagText: String

    init(
        item: MistakeReasonItem,
        validationMessage: Binding<String?>,
        onCancel: @escaping () -> Void,
        onSave: @escaping (MistakeReasonItem, [String]) -> Void
    ) {
        self.item = item
        _validationMessage = validationMessage
        self.onCancel = onCancel
        self.onSave = onSave
        _tagText = State(initialValue: item.manualTags.joined(separator: ", "))
    }

    var body: some View {
        Form {
            Section("ミス理由") {
                Text(item.text)
                TagRow(title: "キーワード分類", tags: item.keywordTags)
            }

            Section("手動タグ") {
                TextField("例: 時制, 設問先読み", text: $tagText, axis: .vertical)
                    .lineLimit(2...4)
            }

            if let validationMessage {
                Section {
                    Label(validationMessage, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("タグ編集")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("キャンセル", action: onCancel)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    onSave(item, parsedTags)
                }
            }
        }
    }

    private var parsedTags: [String] {
        tagText
            .split(separator: ",")
            .map { String($0) }
    }
}

struct TagRow: View {
    let title: String
    let tags: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }
}
