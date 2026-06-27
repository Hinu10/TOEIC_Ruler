import SwiftUI

struct StudyLogsPage: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var editingDraft: StudyLogFormDraft?
    @State private var validationMessage: String?

    var body: some View {
        List {
            if store.appData.studyLogs.isEmpty {
                ContentUnavailableView(
                    "学習記録がありません",
                    systemImage: "square.and.pencil",
                    description: Text("今日の学習内容と正答率を記録してください。")
                )
            } else {
                StudyLogList(
                    studyLogs: store.appData.studyLogs.sorted { $0.studiedOn > $1.studiedOn },
                    materials: store.appData.materials,
                    onEdit: { editingDraft = StudyLogFormDraft(studyLog: $0) },
                    onDelete: delete
                )
            }
        }
        .navigationTitle("学習記録")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    editingDraft = StudyLogFormDraft()
                } label: {
                    Label("追加", systemImage: "plus")
                }
            }
        }
        .sheet(item: $editingDraft) { draft in
            NavigationStack {
                StudyLogFormPage(
                    draft: draft,
                    materials: store.appData.materials,
                    validationMessage: $validationMessage,
                    onCancel: {
                        editingDraft = nil
                        validationMessage = nil
                    },
                    onSave: save
                )
            }
        }
    }

    private func save(_ draft: StudyLogFormDraft) {
        validationMessage = draft.validationMessage
        guard validationMessage == nil else { return }

        do {
            try store.saveStudyLog(draft.makeStudyLog())
            editingDraft = nil
            validationMessage = nil
        } catch {
            validationMessage = "保存に失敗しました"
        }
    }

    private func delete(_ studyLog: StudyLog) {
        try? store.deleteStudyLog(studyLog)
    }
}

struct StudyLogList: View {
    let studyLogs: [StudyLog]
    let materials: [Material]
    let onEdit: (StudyLog) -> Void
    let onDelete: (StudyLog) -> Void

    var body: some View {
        Section {
            ForEach(studyLogs) { studyLog in
                StudyLogCard(
                    studyLog: studyLog,
                    materialName: materials.first { $0.id == studyLog.materialID }?.name,
                    onEdit: { onEdit(studyLog) }
                )
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        onDelete(studyLog)
                    } label: {
                        Label("削除", systemImage: "trash")
                    }
                }
            }
        }
    }
}

struct StudyLogCard: View {
    let studyLog: StudyLog
    let materialName: String?
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(studyLog.studiedOn.formatted(date: .abbreviated, time: .omitted))
                        .font(.headline)
                    Text(materialName ?? "教材未選択")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: onEdit) {
                    Label("編集", systemImage: "pencil")
                }
                .buttonStyle(.borderless)
            }

            HStack {
                Label(studyLog.part.title, systemImage: "number")
                Label("\(studyLog.round)周目", systemImage: "arrow.triangle.2.circlepath")
                Label("\(studyLog.minutes)分", systemImage: "clock")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            if !studyLog.studyRange.isEmpty {
                Text(studyLog.studyRange)
                    .font(.subheadline)
            }

            HStack {
                AccuracyDisplay(studyLog: studyLog)
                Spacer()
                UnderstandingRating(level: studyLog.understanding)
            }

            if let mistakeReasonText = studyLog.mistakeReasonText, !mistakeReasonText.isEmpty {
                Text(mistakeReasonText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}

struct AccuracyDisplay: View {
    let studyLog: StudyLog

    var body: some View {
        if let questionCount = studyLog.questionCount,
           let correctCount = studyLog.correctCount,
           let accuracyRate = studyLog.accuracyRate {
            Label(
                "\(correctCount)/\(questionCount) \(Int((accuracyRate * 100).rounded()))%",
                systemImage: "percent"
            )
            .font(.subheadline.bold())
        } else {
            Label("正答率未入力", systemImage: "percent")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

struct UnderstandingRating: View {
    let level: UnderstandingLevel

    var body: some View {
        Text("\(level.symbol) \(level.title)")
            .font(.subheadline.bold())
    }
}

struct StudyLogFormPage: View {
    @State var draft: StudyLogFormDraft
    let materials: [Material]
    @Binding var validationMessage: String?
    let onCancel: () -> Void
    let onSave: (StudyLogFormDraft) -> Void

    var body: some View {
        Form {
            StudyLogForm(draft: $draft, materials: materials)

            if let validationMessage {
                Section {
                    Label(validationMessage, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(draft.isNew ? "学習記録登録" : "学習記録編集")
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

struct StudyLogForm: View {
    @Binding var draft: StudyLogFormDraft
    let materials: [Material]

    var body: some View {
        Section("基本情報") {
            DatePicker("学習日", selection: $draft.studiedOn, displayedComponents: .date)
            Picker("教材", selection: $draft.materialID) {
                Text("未選択").tag(nil as EntityID?)
                ForEach(materials) { material in
                    Text(material.name).tag(Optional(material.id))
                }
            }
            TextField("学習範囲", text: $draft.studyRange)
            Picker("Part", selection: $draft.part) {
                ForEach(TOEICPart.allCases) { part in
                    Text(part.title).tag(part)
                }
            }
            Stepper("周回数 \(draft.round)", value: $draft.round, in: 1...99)
            Stepper("学習時間 \(draft.minutes)分", value: $draft.minutes, in: 0...600, step: 5)
        }

        Section("正答率") {
            Stepper("正答数 \(draft.correctCount)", value: $draft.correctCount, in: 0...999)
            Stepper("問題数 \(draft.questionCount)", value: $draft.questionCount, in: 0...999)
            HStack {
                Text("自動計算")
                Spacer()
                Text(draft.accuracyText)
                    .foregroundStyle(.secondary)
            }
        }

        Section("理解度") {
            Picker("理解度", selection: $draft.understanding) {
                ForEach(UnderstandingLevel.allCases) { level in
                    Text("\(level.symbol) \(level.title)").tag(level)
                }
            }
            .pickerStyle(.segmented)
        }

        Section("ミス理由") {
            TextField("自由記述", text: $draft.mistakeReasonText, axis: .vertical)
                .lineLimit(3...6)
        }
    }
}

struct StudyLogFormDraft: Identifiable {
    var id: UUID
    var studiedOn: Date
    var materialID: EntityID?
    var studyRange: String
    var part: TOEICPart
    var round: Int
    var minutes: Int
    var questionCount: Int
    var correctCount: Int
    var understanding: UnderstandingLevel
    var mistakeReasonText: String
    var createdAt: Date

    var isNew: Bool { createdAt.timeIntervalSinceNow > -5 }

    init() {
        id = UUID()
        studiedOn = .now
        materialID = nil
        studyRange = ""
        part = .part1
        round = 1
        minutes = 30
        questionCount = 0
        correctCount = 0
        understanding = .triangle
        mistakeReasonText = ""
        createdAt = Date()
    }

    init(studyLog: StudyLog) {
        id = studyLog.id
        studiedOn = studyLog.studiedOn
        materialID = studyLog.materialID
        studyRange = studyLog.studyRange
        part = studyLog.part
        round = studyLog.round
        minutes = studyLog.minutes
        questionCount = studyLog.questionCount ?? 0
        correctCount = studyLog.correctCount ?? 0
        understanding = studyLog.understanding
        mistakeReasonText = studyLog.mistakeReasonText ?? ""
        createdAt = studyLog.createdAt
    }

    var accuracyText: String {
        guard questionCount > 0 else { return "-" }
        return "\(Int((Double(correctCount) / Double(questionCount) * 100).rounded()))%"
    }

    var validationMessage: String? {
        if minutes <= 0 {
            return "学習時間を入力してください"
        }
        if questionCount > 0 && correctCount > questionCount {
            return "正答数は問題数以下にしてください"
        }
        return nil
    }

    func makeStudyLog() -> StudyLog {
        let now = Date()
        let trimmedRange = studyRange.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedMistakeReason = mistakeReasonText.trimmingCharacters(in: .whitespacesAndNewlines)
        return StudyLog(
            id: id,
            studiedOn: studiedOn,
            materialID: materialID,
            studyRange: trimmedRange,
            part: part,
            round: round,
            minutes: minutes,
            questionCount: questionCount > 0 ? questionCount : nil,
            correctCount: questionCount > 0 ? correctCount : nil,
            understanding: understanding,
            mistakeReasonText: trimmedMistakeReason.isEmpty ? nil : trimmedMistakeReason,
            memo: nil,
            createdAt: createdAt,
            updatedAt: now
        )
    }
}
