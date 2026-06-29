import SwiftUI

struct WeaknessNotebookPage: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var selectedPart: TOEICPart = .part1
    @State private var draft = WeaknessNoteDraft()
    @State private var saveMessage: String?

    private var partStudyLogs: [StudyLog] {
        store.appData.studyLogs
            .filter { $0.part == selectedPart }
            .sorted { $0.studiedOn > $1.studiedOn }
    }

    private var partMistakeReasons: [MistakeReason] {
        let usedReasonIDs = Set(partStudyLogs.flatMap(\.mistakeReasonIDs))
        return store.appData.mistakeReasons
            .filter { usedReasonIDs.contains($0.id) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    private var note: WeaknessNote? {
        store.weaknessNote(for: selectedPart)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PartTabs(selectedPart: $selectedPart)

                WeaknessNotebookOverviewCard(
                    part: selectedPart,
                    studyLogCount: partStudyLogs.count,
                    mistakeReasonCount: partMistakeReasons.count,
                    noteUpdatedAt: note?.updatedAt,
                    noteSaved: note != nil
                )

                if let saveMessage {
                    Label {
                        Text(saveMessage)
                    } icon: {
                        Image(systemName: saveMessage == "保存しました" ? "checkmark.circle" : "exclamationmark.triangle")
                    }
                        .font(.subheadline)
                        .foregroundStyle(saveMessage == "保存しました" ? Color.green : Color.red)
                        .padding(.horizontal, 4)
                }

                MistakeReasonReferenceList(
                    part: selectedPart,
                    studyLogs: partStudyLogs,
                    mistakeReasons: partMistakeReasons,
                    materials: store.appData.materials
                )

                WeaknessNoteEditor(
                    draft: $draft,
                    noteExists: note != nil,
                    availableStudyLogs: partStudyLogs,
                    materials: store.appData.materials,
                    onSave: save
                )

                PremiumGeneratedNotePlaceholder(part: selectedPart)
            }
            .padding()
        }
        .navigationTitle("弱点ノート")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: reloadDraft)
        .onChange(of: selectedPart) { _, _ in
            reloadDraft()
        }
    }

    private func syncDraft() {
        draft = WeaknessNoteDraft(note: note, availableStudyLogs: partStudyLogs)
    }

    private func reloadDraft() {
        syncDraft()
        saveMessage = nil
    }

    private func save() {
        guard draft.canCreateNote(existing: note) else {
            saveMessage = "内容を入力してください"
            return
        }

        do {
            try store.saveWeaknessNote(draft.makeNote(existing: note, part: selectedPart, availableStudyLogs: partStudyLogs))
            saveMessage = "保存しました"
            syncDraft()
        } catch {
            saveMessage = "保存に失敗しました"
        }
    }
}

struct PartTabs: View {
    @Binding var selectedPart: TOEICPart

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TOEICPart.allCases) { part in
                    Button {
                        selectedPart = part
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(part.title)
                                .font(.headline)
                            Text(part.name)
                                .font(.caption2)
                                .lineLimit(1)
                        }
                        .foregroundStyle(selectedPart == part ? Color.white : Color.primary)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .frame(minWidth: 96, alignment: .leading)
                        .background(selectedPart == part ? Color.accentColor : Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct WeaknessNotebookOverviewCard: View {
    let part: TOEICPart
    let studyLogCount: Int
    let mistakeReasonCount: Int
    let noteUpdatedAt: Date?
    let noteSaved: Bool

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(part.title)
                            .font(.title3.bold())
                        Text(part.name)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "note.text")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    Label("\(studyLogCount)件の学習記録", systemImage: "square.and.pencil")
                    Label("\(mistakeReasonCount)件のミス理由", systemImage: "exclamationmark.bubble")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                if let noteUpdatedAt {
                    Text("最終更新 \(noteUpdatedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if noteSaved {
                    Text("このPartにはノートがあります")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("このPartにはまだノートがありません")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct MistakeReasonReferenceList: View {
    let part: TOEICPart
    let studyLogs: [StudyLog]
    let mistakeReasons: [MistakeReason]
    let materials: [Material]

    private var materialByID: [EntityID: Material] {
        Dictionary(uniqueKeysWithValues: materials.map { ($0.id, $0) })
    }

    private var mistakeReasonByID: [EntityID: MistakeReason] {
        Dictionary(uniqueKeysWithValues: mistakeReasons.map { ($0.id, $0) })
    }

    var body: some View {
        GroupBox("ミス理由と学習記録") {
            VStack(alignment: .leading, spacing: 16) {
                if mistakeReasons.isEmpty {
                    ContentUnavailableView(
                        "\(part.title)のミス理由はまだありません",
                        systemImage: "exclamationmark.triangle",
                        description: Text("学習記録に紐づいたミス理由があると、ここに整理表示されます。")
                    )
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ミス理由")
                            .font(.headline)
                        TagWrap(tags: mistakeReasons.map { "\($0.category.title)・\($0.title)" })
                    }
                }

                Divider()

                if studyLogs.isEmpty {
                    ContentUnavailableView(
                        "参照元学習記録がありません",
                        systemImage: "calendar",
                        description: Text("このPartの学習ログが追加されると、日付と教材名を表示できます。")
                    )
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("参照元学習記録")
                            .font(.headline)

                        ForEach(studyLogs) { studyLog in
                            WeaknessStudyLogCard(
                                studyLog: studyLog,
                                material: studyLog.materialID.flatMap { materialByID[$0] },
                                mistakeReasons: studyLog.mistakeReasonIDs.compactMap { mistakeReasonByID[$0] }
                            )
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct WeaknessStudyLogCard: View {
    let studyLog: StudyLog
    let material: Material?
    let mistakeReasons: [MistakeReason]

    private var reasonTags: [String] {
        mistakeReasons.map { "\($0.category.title)・\($0.title)" }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(studyLog.studiedOn.formatted(date: .abbreviated, time: .omitted))
                        .font(.headline)
                    Text(material?.name ?? "教材未設定")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(studyLog.understanding.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Label("\(studyLog.minutes)分", systemImage: "clock")
                Label(studyLog.part.title, systemImage: "target")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if !reasonTags.isEmpty {
                TagWrap(tags: reasonTags)
            }

            if let memo = studyLog.memo, !memo.isEmpty {
                Text(memo)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct WeaknessNoteEditor: View {
    @Binding var draft: WeaknessNoteDraft
    let noteExists: Bool
    let availableStudyLogs: [StudyLog]
    let materials: [Material]
    let onSave: () -> Void

    private var selectedStudyLog: StudyLog? {
        guard let selectedStudyLogID = draft.selectedStudyLogID else { return nil }
        return availableStudyLogs.first { $0.id == selectedStudyLogID }
    }

    private var selectedMaterial: Material? {
        guard let materialID = selectedStudyLog?.materialID else { return nil }
        return materials.first { $0.id == materialID }
    }

    var body: some View {
        GroupBox("手動ノート") {
            VStack(alignment: .leading, spacing: 12) {
                TextField("手動ノート", text: $draft.manualNoteText, axis: .vertical)
                    .lineLimit(4...10)
                TextField("ミス理由メモ", text: $draft.mistakeReasonText, axis: .vertical)
                    .lineLimit(2...6)
                TextField("手動タグ, カンマ区切り", text: $draft.manualTagsText)
                TextField("キーワードタグ, カンマ区切り", text: $draft.keywordTagsText)

                Picker("参照元学習記録", selection: $draft.selectedStudyLogID) {
                    Text("未選択").tag(Optional<EntityID>.none)
                    ForEach(availableStudyLogs) { studyLog in
                        Text(studyLog.studiedOn.formatted(date: .abbreviated, time: .omitted))
                            .tag(Optional(studyLog.id))
                    }
                }

                if let selectedStudyLog {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("選択中の記録")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(selectedStudyLog.studiedOn.formatted(date: .abbreviated, time: .omitted))
                            .font(.subheadline.weight(.semibold))
                        Text(selectedMaterial?.name ?? "教材未設定")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                HStack {
                    Label(noteExists ? "既存ノートを更新" : "新規ノートを保存", systemImage: "square.and.arrow.down")
                    Spacer()
                    Button("保存", action: onSave)
                        .buttonStyle(.borderedProminent)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct PremiumGeneratedNotePlaceholder: View {
    let part: TOEICPart

    var body: some View {
        GroupBox("AI生成ノート用プレースホルダ") {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(part.title)の手動ノートと学習記録を、将来の自動生成ノートに差し替えやすい形で保持します。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                ContentUnavailableView(
                    "Premiumで自動生成予定",
                    systemImage: "sparkles",
                    description: Text("現状は記録済みデータの整理表示のみを行います。")
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct TagWrap: View {
    let tags: [String]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.caption.weight(.semibold))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.accentColor.opacity(0.12))
                    .foregroundStyle(Color.accentColor)
                    .clipShape(Capsule())
            }
        }
    }
}

struct WeaknessNoteDraft {
    var manualNoteText: String
    var mistakeReasonText: String
    var manualTagsText: String
    var keywordTagsText: String
    var selectedStudyLogID: EntityID?

    init() {
        manualNoteText = ""
        mistakeReasonText = ""
        manualTagsText = ""
        keywordTagsText = ""
        selectedStudyLogID = nil
    }

    init(note: WeaknessNote?, availableStudyLogs: [StudyLog]) {
        manualNoteText = note?.manualNoteText ?? ""
        mistakeReasonText = note?.mistakeReasonText ?? ""
        manualTagsText = note?.manualTags.joined(separator: ", ") ?? ""
        keywordTagsText = note?.keywordTags.joined(separator: ", ") ?? ""
        selectedStudyLogID = note?.studyLogID ?? availableStudyLogs.first?.id
    }

    var hasUserInput: Bool {
        !manualNoteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        || !mistakeReasonText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        || !manualTags.isEmpty
        || !keywordTags.isEmpty
        || selectedStudyLogID != nil
    }

    var manualTags: [String] {
        Self.splitTags(manualTagsText)
    }

    var keywordTags: [String] {
        Self.splitTags(keywordTagsText)
    }

    func canCreateNote(existing: WeaknessNote?) -> Bool {
        existing != nil || hasUserInput
    }

    func makeNote(existing: WeaknessNote?, part: TOEICPart, availableStudyLogs: [StudyLog]) -> WeaknessNote {
        let now = Date()
        let selectedStudyLog = selectedStudyLogID.flatMap { id in
            availableStudyLogs.first { $0.id == id }
        } ?? (existing?.studyLogID.flatMap { id in availableStudyLogs.first { $0.id == id } })

        return WeaknessNote(
            id: existing?.id ?? UUID(),
            part: part,
            manualNoteText: manualNoteText.trimmingCharacters(in: .whitespacesAndNewlines),
            mistakeReasonText: mistakeReasonText.trimmingCharacters(in: .whitespacesAndNewlines),
            manualTags: manualTags,
            keywordTags: keywordTags,
            studyLogID: selectedStudyLog?.id ?? existing?.studyLogID,
            materialID: selectedStudyLog?.materialID ?? existing?.materialID,
            studyDate: selectedStudyLog?.studiedOn ?? existing?.studyDate,
            relatedStudyLogIDs: availableStudyLogs.map(\.id),
            aiGeneratedNoteText: existing?.aiGeneratedNoteText,
            createdAt: existing?.createdAt ?? now,
            updatedAt: now
        )
    }

    private static func splitTags(_ rawValue: String) -> [String] {
        rawValue
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

#Preview {
    NavigationStack {
        WeaknessNotebookPage()
            .environmentObject(AppDataStore(localStore: LocalAppDataStore(defaults: .standard)))
    }
}
