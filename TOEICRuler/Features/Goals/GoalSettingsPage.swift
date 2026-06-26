import SwiftUI

struct GoalSettingsPage: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var draft = GoalFormDraft()
    @State private var validationMessage: String?
    @State private var saveMessage: String?

    var body: some View {
        Form {
            if let goal = store.appData.userGoal {
                Section {
                    GoalSummaryCard(goal: goal)
                }
            } else {
                Section {
                    ContentUnavailableView(
                        "目標が未設定です",
                        systemImage: "flag",
                        description: Text("今日の学習提案に使う目標を設定してください。")
                    )
                }
            }

            GoalForm(draft: $draft)

            if let validationMessage {
                Section {
                    Label(validationMessage, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                }
            }

            Section {
                Button {
                    save()
                } label: {
                    Label("目標を保存", systemImage: "square.and.arrow.down")
                }
            }

            if let saveMessage {
                Section {
                    Label(saveMessage, systemImage: "checkmark.circle")
                        .foregroundStyle(.green)
                }
            }
        }
        .navigationTitle("目標設定")
        .onAppear {
            draft = GoalFormDraft(goal: store.appData.userGoal)
        }
    }

    private func save() {
        validationMessage = draft.validationMessage
        guard validationMessage == nil else { return }

        do {
            try store.saveGoal(draft.makeGoal(existing: store.appData.userGoal))
            draft = GoalFormDraft(goal: store.appData.userGoal)
            saveMessage = "保存しました"
        } catch {
            validationMessage = "保存に失敗しました"
        }
    }
}

struct GoalSummaryCard: View {
    let goal: UserGoal

    private var daysUntilExam: Int {
        Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now), to: Calendar.current.startOfDay(for: goal.examDate)).day ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(goal.currentScore)")
                    .font(.title2.bold())
                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)
                Text("\(goal.targetScore)")
                    .font(.title2.bold())
            }

            LabeledContent("試験日", value: goal.examDate.formatted(date: .abbreviated, time: .omitted))
            LabeledContent("試験日まで", value: daysUntilExam >= 0 ? "あと\(daysUntilExam)日" : "\(abs(daysUntilExam))日前")
            LabeledContent("1日の学習時間", value: "\(goal.dailyStudyMinutes)分")
            LabeledContent("苦手Part", value: goal.weakParts.sorted { $0.number < $1.number }.map(\.title).joined(separator: ", "))
        }
        .padding(.vertical, 4)
    }
}

struct GoalForm: View {
    @Binding var draft: GoalFormDraft

    var body: some View {
        Section("スコア") {
            Stepper("現在スコア \(draft.currentScore)", value: $draft.currentScore, in: 10...990, step: 5)
            Stepper("目標スコア \(draft.targetScore)", value: $draft.targetScore, in: 10...990, step: 5)
        }

        Section("学習条件") {
            DatePicker("試験日", selection: $draft.examDate, displayedComponents: .date)
            Stepper("1日の学習時間 \(draft.dailyStudyMinutes)分", value: $draft.dailyStudyMinutes, in: 5...600, step: 5)
        }

        Section("苦手Part") {
            PartSelector(selection: $draft.weakParts)
        }
    }
}

struct GoalFormDraft {
    var currentScore = 500
    var targetScore = 700
    var examDate = Calendar.current.date(byAdding: .month, value: 3, to: .now) ?? .now
    var dailyStudyMinutes = 60
    var weakParts: Set<TOEICPart> = []

    init() {}

    init(goal: UserGoal?) {
        guard let goal else { return }
        currentScore = goal.currentScore
        targetScore = goal.targetScore
        examDate = goal.examDate
        dailyStudyMinutes = goal.dailyStudyMinutes
        weakParts = Set(goal.weakParts)
    }

    var validationMessage: String? {
        if targetScore <= currentScore {
            return "目標スコアは現在スコアより高くしてください"
        }
        if Calendar.current.startOfDay(for: examDate) < Calendar.current.startOfDay(for: .now) {
            return "試験日は今日以降にしてください"
        }
        if weakParts.isEmpty {
            return "苦手Partを1つ以上選択してください"
        }
        return nil
    }

    func makeGoal(existing: UserGoal?) -> UserGoal {
        let now = Date()
        return UserGoal(
            id: existing?.id ?? UUID(),
            currentScore: currentScore,
            targetScore: targetScore,
            examDate: examDate,
            dailyStudyMinutes: dailyStudyMinutes,
            weakParts: weakParts.sorted { $0.number < $1.number },
            createdAt: existing?.createdAt ?? now,
            updatedAt: now
        )
    }
}

#Preview {
    NavigationStack {
        GoalSettingsPage()
            .environmentObject(AppDataStore(localStore: LocalAppDataStore(defaults: .standard)))
    }
}
