import SwiftUI

struct TodayRecommendation: Identifiable, Equatable {
    var id = UUID()
    var title: String
    var part: TOEICPart
    var materialID: EntityID?
    var studyRange: String
    var minutes: Int
    var round: Int
    var reason: String
}

func createTodayRecommendations(
    goal: UserGoal?,
    materials: [Material],
    studyLogs: [StudyLog],
    today: Date = .now
) -> [TodayRecommendation] {
    guard let goal, !materials.isEmpty else { return [] }

    let calendar = Calendar.current
    let startOfToday = calendar.startOfDay(for: today)
    let recentLogs = studyLogs.filter {
        guard let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: $0.studiedOn), to: startOfToday).day else {
            return false
        }
        return days >= 0 && days <= 7
    }
    let recentlyStudiedParts = Set(recentLogs.map(\.part))
    let weakParts = goal.weakParts
    let targetMinutes = max(15, goal.dailyStudyMinutes / 2)

    var recommendations: [TodayRecommendation] = []

    for part in weakParts where !recentlyStudiedParts.contains(part) {
        if let material = bestMaterial(for: part, materials: materials) {
            recommendations.append(
                TodayRecommendation(
                    title: "\(part.title)を重点復習",
                    part: part,
                    materialID: material.id,
                    studyRange: "未学習・不安な範囲",
                    minutes: targetMinutes,
                    round: max(material.currentRound, 1),
                    reason: "苦手Partで、直近7日間の学習記録がありません。"
                )
            )
        }
    }

    if recommendations.count < 3 {
        let unfinishedMaterials = materials
            .filter { $0.progressRate < 100 }
            .sorted { $0.progressRate < $1.progressRate }

        for material in unfinishedMaterials where recommendations.count < 3 {
            guard let part = material.targetParts.first(where: { !recentlyStudiedParts.contains($0) }) ?? material.targetParts.first else {
                continue
            }
            recommendations.append(
                TodayRecommendation(
                    title: "\(material.name)を進める",
                    part: part,
                    materialID: material.id,
                    studyRange: "次に進める範囲",
                    minutes: targetMinutes,
                    round: max(material.currentRound, 1),
                    reason: "教材進捗が\(Int(material.progressRate))%のため、完了まで進めます。"
                )
            )
        }
    }

    if recommendations.isEmpty, let material = materials.first, let part = material.targetParts.first {
        recommendations.append(
            TodayRecommendation(
                title: "今日の学習を記録",
                part: part,
                materialID: material.id,
                studyRange: "復習した範囲",
                minutes: targetMinutes,
                round: max(material.currentRound, 1),
                reason: "最近の学習記録がそろっているため、継続記録を優先します。"
            )
        )
    }

    return Array(recommendations.prefix(3))
}

private func bestMaterial(for part: TOEICPart, materials: [Material]) -> Material? {
    materials
        .filter { $0.targetParts.contains(part) }
        .sorted { lhs, rhs in
            if lhs.progressRate == rhs.progressRate {
                return lhs.updatedAt > rhs.updatedAt
            }
            return lhs.progressRate < rhs.progressRate
        }
        .first
}

struct TodayPage: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var logDraft: StudyLogFormDraft?
    @State private var validationMessage: String?

    private var recommendations: [TodayRecommendation] {
        createTodayRecommendations(
            goal: store.appData.userGoal,
            materials: store.appData.materials,
            studyLogs: store.appData.studyLogs
        )
    }

    var body: some View {
        List {
            if let goal = store.appData.userGoal {
                Section {
                    GoalMiniSummary(goal: goal)
                }
            } else {
                Section {
                    ContentUnavailableView(
                        "目標が未設定です",
                        systemImage: "flag",
                        description: Text("今日の学習提案には目標スコアと苦手Partが必要です。")
                    )
                }
            }

            if store.appData.materials.isEmpty {
                Section {
                    ContentUnavailableView(
                        "教材が未登録です",
                        systemImage: "books.vertical",
                        description: Text("教材を登録すると、進捗に合わせて今日の学習を提案できます。")
                    )
                }
            } else if recommendations.isEmpty {
                Section {
                    ContentUnavailableView(
                        "提案に必要な情報が不足しています",
                        systemImage: "calendar.badge.exclamationmark",
                        description: Text("目標と教材を確認してください。")
                    )
                }
            } else {
                Section("今日の推奨メニュー") {
                    ForEach(recommendations) { recommendation in
                        TodayMenuCard(
                            recommendation: recommendation,
                            materialName: materialName(for: recommendation.materialID),
                            onStart: {
                                logDraft = StudyLogFormDraft(recommendation: recommendation)
                            }
                        )
                    }
                }
            }
        }
        .navigationTitle("今日の学習")
        .sheet(item: $logDraft) { draft in
            NavigationStack {
                StudyLogFormPage(
                    draft: draft,
                    materials: store.appData.materials,
                    validationMessage: $validationMessage,
                    onCancel: {
                        logDraft = nil
                        validationMessage = nil
                    },
                    onSave: save
                )
            }
        }
    }

    private func materialName(for id: EntityID?) -> String {
        guard let id, let material = store.appData.materials.first(where: { $0.id == id }) else {
            return "教材未選択"
        }
        return material.name
    }

    private func save(_ draft: StudyLogFormDraft) {
        validationMessage = draft.validationMessage
        guard validationMessage == nil else { return }

        do {
            try store.saveStudyLog(draft.makeStudyLog())
            logDraft = nil
            validationMessage = nil
        } catch {
            validationMessage = "保存に失敗しました"
        }
    }
}

struct TodayMenuCard: View {
    let recommendation: TodayRecommendation
    let materialName: String
    let onStart: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.title)
                        .font(.headline)
                    Text(materialName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: onStart) {
                    Label("記録", systemImage: "square.and.pencil")
                }
                .buttonStyle(.bordered)
            }

            HStack {
                Label(recommendation.part.title, systemImage: "number")
                Label("\(recommendation.minutes)分", systemImage: "clock")
                Label("\(recommendation.round)周目", systemImage: "arrow.triangle.2.circlepath")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            if !recommendation.studyRange.isEmpty {
                Text(recommendation.studyRange)
                    .font(.subheadline)
            }

            RecommendationReason(text: recommendation.reason)
        }
        .padding(.vertical, 6)
    }
}

struct GoalMiniSummary: View {
    let goal: UserGoal

    private var daysUntilExam: Int {
        Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: .now),
            to: Calendar.current.startOfDay(for: goal.examDate)
        ).day ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("\(goal.currentScore) → \(goal.targetScore)", systemImage: "flag")
                Spacer()
                Text(daysUntilExam >= 0 ? "あと\(daysUntilExam)日" : "\(abs(daysUntilExam))日前")
                    .foregroundStyle(.secondary)
            }
            Text("苦手Part: \(goal.weakParts.sorted { $0.number < $1.number }.map(\.title).joined(separator: ", "))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct RecommendationReason: View {
    let text: String

    var body: some View {
        Label(text, systemImage: "lightbulb")
            .font(.footnote)
            .foregroundStyle(.secondary)
    }
}

extension StudyLogFormDraft {
    init(recommendation: TodayRecommendation) {
        id = UUID()
        studiedOn = .now
        materialID = recommendation.materialID
        studyRange = recommendation.studyRange
        part = recommendation.part
        round = recommendation.round
        minutes = recommendation.minutes
        questionCount = 0
        correctCount = 0
        understanding = .triangle
        mistakeReasonText = ""
        createdAt = Date()
    }
}
