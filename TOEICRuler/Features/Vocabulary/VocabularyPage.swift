import SwiftUI

struct VocabularyPage: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var editingDraft: VocabularyFormDraft?
    @State private var testingItem: VocabularyItem?
    @State private var validationMessage: String?

    var body: some View {
        List {
            if store.appData.vocabularyItems.isEmpty {
                ContentUnavailableView(
                    "単語が未登録です",
                    systemImage: "textformat.abc",
                    description: Text("自分で覚えたい単語や意味を登録してください。")
                )
            } else {
                VocabularyList(
                    items: store.appData.vocabularyItems,
                    materials: store.appData.materials,
                    onEdit: { editingDraft = VocabularyFormDraft(item: $0) },
                    onTest: { testingItem = $0 },
                    onDelete: delete
                )
            }
        }
        .navigationTitle("単語チェック")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    editingDraft = VocabularyFormDraft()
                } label: {
                    Label("追加", systemImage: "plus")
                }
            }
        }
        .sheet(item: $editingDraft) { draft in
            NavigationStack {
                VocabularyFormPage(
                    draft: draft,
                    materials: vocabularyMaterials,
                    validationMessage: $validationMessage,
                    onCancel: {
                        editingDraft = nil
                        validationMessage = nil
                    },
                    onSave: save
                )
            }
        }
        .sheet(item: $testingItem) { item in
            NavigationStack {
                VocabularyTestPage(
                    item: item,
                    onCancel: { testingItem = nil },
                    onRate: rate
                )
            }
        }
    }

    private var vocabularyMaterials: [Material] {
        store.appData.materials.filter { $0.type == .vocabularyBook }
    }

    private func save(_ draft: VocabularyFormDraft) {
        validationMessage = draft.validationMessage
        guard validationMessage == nil else { return }

        do {
            try store.saveVocabularyItem(draft.makeVocabularyItem())
            editingDraft = nil
            validationMessage = nil
        } catch {
            validationMessage = "保存に失敗しました"
        }
    }

    private func delete(_ item: VocabularyItem) {
        try? store.deleteVocabularyItem(item)
    }

    private func rate(_ item: VocabularyItem, rating: VocabularyRating) {
        let result = VocabularyCheckResult(
            id: UUID(),
            vocabularyItemID: item.id,
            checkedAt: .now,
            rating: rating
        )
        try? store.saveVocabularyCheckResult(result)
        testingItem = nil
    }
}

struct VocabularyList: View {
    let items: [VocabularyItem]
    let materials: [Material]
    let onEdit: (VocabularyItem) -> Void
    let onTest: (VocabularyItem) -> Void
    let onDelete: (VocabularyItem) -> Void

    var body: some View {
        Section {
            ForEach(items) { item in
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.term)
                                .font(.headline)
                            Text(materialName(for: item))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        SelfRatingBadge(rating: item.latestResult)
                    }

                    HStack {
                        Label("\(item.round)周目", systemImage: "arrow.triangle.2.circlepath")
                        if let partOfSpeech = item.partOfSpeech, !partOfSpeech.isEmpty {
                            Label(partOfSpeech, systemImage: "tag")
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    if !item.sourceRange.isEmpty {
                        Text(item.sourceRange)
                            .font(.subheadline)
                    }

                    HStack {
                        Button {
                            onTest(item)
                        } label: {
                            Label("確認", systemImage: "checkmark.circle")
                        }
                        .buttonStyle(.bordered)

                        Button {
                            onEdit(item)
                        } label: {
                            Label("編集", systemImage: "pencil")
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .padding(.vertical, 6)
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        onDelete(item)
                    } label: {
                        Label("削除", systemImage: "trash")
                    }
                }
            }
        }
    }

    private func materialName(for item: VocabularyItem) -> String {
        guard let id = item.materialID ?? item.sourceMaterialID,
              let material = materials.first(where: { $0.id == id }) else {
            return "単語帳教材未選択"
        }
        return material.name
    }
}

struct SelfRatingBadge: View {
    let rating: VocabularyRating?

    var body: some View {
        if let rating {
            Text("\(rating.symbol) \(rating.title)")
                .font(.subheadline.bold())
        } else {
            Text("未確認")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

struct VocabularyFormPage: View {
    @State var draft: VocabularyFormDraft
    let materials: [Material]
    @Binding var validationMessage: String?
    let onCancel: () -> Void
    let onSave: (VocabularyFormDraft) -> Void

    var body: some View {
        Form {
            VocabularyForm(draft: $draft, materials: materials)

            if let validationMessage {
                Section {
                    Label(validationMessage, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(draft.isNew ? "単語登録" : "単語編集")
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

struct VocabularyForm: View {
    @Binding var draft: VocabularyFormDraft
    let materials: [Material]

    var body: some View {
        Section("単語") {
            TextField("単語・表現", text: $draft.term)
            TextField("意味", text: $draft.meaning, axis: .vertical)
                .lineLimit(2...4)
            TextField("メモ", text: $draft.userMemo, axis: .vertical)
                .lineLimit(2...5)
        }

        Section("教材") {
            Picker("単語帳教材", selection: $draft.materialID) {
                Text("未選択").tag(nil as EntityID?)
                ForEach(materials) { material in
                    Text(material.name).tag(Optional(material.id))
                }
            }
            TextField("品詞", text: $draft.partOfSpeech)
            TextField("出典範囲", text: $draft.sourceRange)
            Stepper("周回数 \(draft.round)", value: $draft.round, in: 1...99)
        }
    }
}

struct VocabularyTestPage: View {
    let item: VocabularyItem
    let onCancel: () -> Void
    let onRate: (VocabularyItem, VocabularyRating) -> Void
    @State private var isAnswerVisible = false

    var body: some View {
        VStack(spacing: 20) {
            VocabularyTestCard(item: item, isAnswerVisible: isAnswerVisible)

            Button {
                isAnswerVisible.toggle()
            } label: {
                Label(isAnswerVisible ? "意味を隠す" : "意味を表示", systemImage: isAnswerVisible ? "eye.slash" : "eye")
            }
            .buttonStyle(.borderedProminent)

            SelfRatingButtons { rating in
                onRate(item, rating)
            }
        }
        .padding()
        .navigationTitle("確認テスト")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる", action: onCancel)
            }
        }
    }
}

struct VocabularyTestCard: View {
    let item: VocabularyItem
    let isAnswerVisible: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(item.term)
                .font(.largeTitle.bold())

            Text(roundHint)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if isAnswerVisible {
                Text(item.meaning)
                    .font(.title3)
                if let userMemo = item.userMemo, !userMemo.isEmpty {
                    Text(userMemo)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("意味とメモは非表示です")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var roundHint: String {
        switch item.round {
        case 1:
            return "1周目: 見たことがあるかを確認"
        case 2:
            return "2周目: 意味をすぐ思い出せるかを確認"
        default:
            return "\(item.round)周目: 例文や使い方まで確認"
        }
    }
}

struct SelfRatingButtons: View {
    let onRate: (VocabularyRating) -> Void

    var body: some View {
        HStack {
            ForEach(VocabularyRating.allCases) { rating in
                Button {
                    onRate(rating)
                } label: {
                    Text("\(rating.symbol) \(rating.title)")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

struct VocabularyFormDraft: Identifiable {
    var id: UUID
    var materialID: EntityID?
    var term: String
    var meaning: String
    var userMemo: String
    var partOfSpeech: String
    var sourceRange: String
    var round: Int
    var lastCheckedAt: Date?
    var latestResult: VocabularyRating?
    var createdAt: Date

    var isNew: Bool { createdAt.timeIntervalSinceNow > -5 }

    init() {
        id = UUID()
        materialID = nil
        term = ""
        meaning = ""
        userMemo = ""
        partOfSpeech = ""
        sourceRange = ""
        round = 1
        lastCheckedAt = nil
        latestResult = nil
        createdAt = Date()
    }

    init(item: VocabularyItem) {
        id = item.id
        materialID = item.materialID ?? item.sourceMaterialID
        term = item.term
        meaning = item.meaning
        userMemo = item.userMemo ?? ""
        partOfSpeech = item.partOfSpeech ?? ""
        sourceRange = item.sourceRange
        round = item.round
        lastCheckedAt = item.lastCheckedAt
        latestResult = item.latestResult
        createdAt = item.createdAt
    }

    var validationMessage: String? {
        if term.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "単語を入力してください"
        }
        if meaning.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "意味を入力してください"
        }
        return nil
    }

    func makeVocabularyItem() -> VocabularyItem {
        let now = Date()
        let trimmedMemo = userMemo.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPartOfSpeech = partOfSpeech.trimmingCharacters(in: .whitespacesAndNewlines)
        return VocabularyItem(
            id: id,
            materialID: materialID,
            term: term.trimmingCharacters(in: .whitespacesAndNewlines),
            meaning: meaning.trimmingCharacters(in: .whitespacesAndNewlines),
            userMemo: trimmedMemo.isEmpty ? nil : trimmedMemo,
            partOfSpeech: trimmedPartOfSpeech.isEmpty ? nil : trimmedPartOfSpeech,
            sourceRange: sourceRange.trimmingCharacters(in: .whitespacesAndNewlines),
            round: round,
            lastCheckedAt: lastCheckedAt,
            latestResult: latestResult,
            sourceMaterialID: materialID,
            createdAt: createdAt,
            updatedAt: now
        )
    }
}
