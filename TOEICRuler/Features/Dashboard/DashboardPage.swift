import SwiftUI

struct DashboardPage: View {
    @EnvironmentObject private var store: AppDataStore

    private var summary: DashboardSummary {
        DashboardSummary(appData: store.appData)
    }

    var body: some View {
        List {
            DashboardGoalSection(summary: summary)
            DashboardQuickActionsSection()
            DashboardWeeklySection(summary: summary)
            DashboardMaterialsSection(summary: summary)
            DashboardWeaknessSection(partSummaries: summary.partSummaries)
            DashboardVocabularySection(summary: summary)
            DashboardPremiumAnalyticsSection()
            DashboardRecentLogsSection(logs: summary.recentLogs, materials: store.appData.materials)
        }
        .navigationTitle("ダッシュボード")
    }
}

struct DashboardSummary {
    let appData: AppData
    private let calendar = Calendar.current
    private let today = Date()

    var goal: UserGoal? {
        appData.userGoal
    }

    var daysUntilExam: Int? {
        guard let goal else { return nil }
        return calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: today),
            to: calendar.startOfDay(for: goal.examDate)
        ).day
    }

    var scoreGap: Int? {
        guard let goal else { return nil }
        return max(goal.targetScore - goal.currentScore, 0)
    }

    var weeklyLogs: [StudyLog] {
        appData.studyLogs.filter { log in
            guard let days = calendar.dateComponents(
                [.day],
                from: calendar.startOfDay(for: log.studiedOn),
                to: calendar.startOfDay(for: today)
            ).day else {
                return false
            }
            return days >= 0 && days <= 6
        }
    }

    var weeklyStudyMinutes: Int {
        weeklyLogs.reduce(0) { $0 + $1.minutes }
    }

    var weeklyStudyDays: Int {
        Set(weeklyLogs.map { calendar.startOfDay(for: $0.studiedOn) }).count
    }

    var dailyTargetMinutes: Int {
        goal?.dailyStudyMinutes ?? 0
    }

    var weeklyTargetMinutes: Int {
        dailyTargetMinutes * 7
    }

    var weeklyProgressRate: Double {
        guard weeklyTargetMinutes > 0 else { return 0 }
        return Double(weeklyStudyMinutes) / Double(weeklyTargetMinutes)
    }

    var studyStreakDays: Int {
        let studiedDays = Set(appData.studyLogs.map { calendar.startOfDay(for: $0.studiedOn) })
        guard !studiedDays.isEmpty else { return 0 }

        var streak = 0
        var cursor = calendar.startOfDay(for: today)
        while studiedDays.contains(cursor) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: cursor) else {
                break
            }
            cursor = previousDay
        }
        return streak
    }

    var averageMaterialProgress: Double {
        guard !appData.materials.isEmpty else { return 0 }
        let total = appData.materials.reduce(0) { $0 + $1.progressRate }
        return total / Double(appData.materials.count)
    }

    var unfinishedMaterials: [Material] {
        appData.materials
            .filter { $0.progressRate < 100 }
            .sorted { lhs, rhs in
                if lhs.progressRate == rhs.progressRate {
                    return lhs.updatedAt > rhs.updatedAt
                }
                return lhs.progressRate < rhs.progressRate
            }
    }

    var vocabularyNeedsReviewCount: Int {
        appData.vocabularyItems.filter { item in
            item.latestResult == nil || item.latestResult == .triangle || item.latestResult == .cross
        }.count
    }

    var vocabularyMasteredCount: Int {
        appData.vocabularyItems.filter { $0.latestResult == .circle }.count
    }

    var vocabularyCircleCount: Int {
        appData.vocabularyItems.filter { $0.latestResult == .circle }.count
    }

    var vocabularyTriangleCount: Int {
        appData.vocabularyItems.filter { $0.latestResult == .triangle }.count
    }

    var vocabularyCrossCount: Int {
        appData.vocabularyItems.filter { $0.latestResult == .cross }.count
    }

    var recentLogs: [StudyLog] {
        Array(appData.studyLogs.sorted { $0.studiedOn > $1.studiedOn }.prefix(5))
    }

    var partSummaries: [DashboardPartSummary] {
        TOEICPart.allCases.map { part in
            let logs = appData.studyLogs.filter { $0.part == part }
            let mistakeReasons = appData.mistakeReasons.filter { $0.part == part }
            let weakGoal = goal?.weakParts.contains(part) == true
            return DashboardPartSummary(part: part, logs: logs, mistakeReasons: mistakeReasons, isGoalWeakPart: weakGoal)
        }
        .sorted { lhs, rhs in
            if lhs.priorityScore == rhs.priorityScore {
                return lhs.part.number < rhs.part.number
            }
            return lhs.priorityScore > rhs.priorityScore
        }
    }
}

struct DashboardPartSummary: Identifiable {
    let part: TOEICPart
    let logs: [StudyLog]
    let mistakeReasons: [MistakeReason]
    let isGoalWeakPart: Bool

    var id: TOEICPart { part }

    var totalMinutes: Int {
        logs.reduce(0) { $0 + $1.minutes }
    }

    var mistakeCount: Int {
        let textMistakes = logs.filter { ($0.mistakeReasonText ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false }.count
        return max(textMistakes, mistakeReasons.count)
    }

    var lowUnderstandingCount: Int {
        logs.filter { $0.understanding == .triangle || $0.understanding == .cross }.count
    }

    var averageAccuracyRate: Double? {
        let answeredLogs = logs.filter { ($0.questionCount ?? 0) > 0 && $0.correctCount != nil }
        let questionTotal = answeredLogs.reduce(0) { $0 + ($1.questionCount ?? 0) }
        guard questionTotal > 0 else { return nil }
        let correctTotal = answeredLogs.reduce(0) { $0 + ($1.correctCount ?? 0) }
        return Double(correctTotal) / Double(questionTotal)
    }

    var priorityScore: Int {
        let accuracyPenalty: Int
        if let averageAccuracyRate {
            accuracyPenalty = averageAccuracyRate < 0.7 ? 4 : averageAccuracyRate < 0.85 ? 2 : 0
        } else {
            accuracyPenalty = 0
        }
        return (isGoalWeakPart ? 8 : 0) + mistakeCount * 3 + lowUnderstandingCount * 2 + accuracyPenalty
    }
}

struct DashboardQuickActionsSection: View {
    var body: some View {
        Section("ショートカット") {
            NavigationLink {
                RouteContentView(route: .today)
            } label: {
                Label("今日の学習メニュー", systemImage: AppRoute.today.systemImage)
            }

            NavigationLink {
                RouteContentView(route: .materials)
            } label: {
                Label("教材を確認", systemImage: AppRoute.materials.systemImage)
            }

            NavigationLink {
                RouteContentView(route: .studyLogs)
            } label: {
                Label("学習記録を追加", systemImage: AppRoute.studyLogs.systemImage)
            }
        }
    }
}

struct DashboardGoalSection: View {
    let summary: DashboardSummary

    var body: some View {
        Section("目標") {
            if let goal = summary.goal {
                HStack(spacing: 12) {
                    DashboardMetricTile(title: "スコア", value: "\(goal.currentScore)→\(goal.targetScore)", systemImage: "flag")
                    DashboardMetricTile(title: "残り", value: daysText, systemImage: "calendar")
                    DashboardMetricTile(title: "差分", value: "\(summary.scoreGap ?? 0)", systemImage: "arrow.up.right")
                }

                if !goal.weakParts.isEmpty {
                    DashboardTagLine(title: "重点Part", values: goal.weakParts.sorted { $0.number < $1.number }.map(\.title))
                }
            } else {
                ContentUnavailableView(
                    "目標が未設定です",
                    systemImage: "flag",
                    description: Text("目標スコアと受験日を設定すると、進捗をここで確認できます。")
                )
            }
        }
    }

    private var daysText: String {
        guard let days = summary.daysUntilExam else { return "-" }
        return days >= 0 ? "\(days)日" : "\(abs(days))日前"
    }
}

struct DashboardWeeklySection: View {
    let summary: DashboardSummary

    var body: some View {
        Section("直近7日") {
            HStack(spacing: 12) {
                DashboardMetricTile(title: "学習時間", value: "\(summary.weeklyStudyMinutes)分", systemImage: "clock")
                DashboardMetricTile(title: "学習日数", value: "\(summary.weeklyStudyDays)日", systemImage: "checkmark.circle")
                DashboardMetricTile(title: "連続", value: "\(summary.studyStreakDays)日", systemImage: "flame")
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("週間目標")
                    Spacer()
                    Text("\(summary.weeklyStudyMinutes)/\(summary.weeklyTargetMinutes)分")
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)

                ProgressBar(value: summary.weeklyProgressRate)
            }
            .padding(.vertical, 4)
        }
    }
}

struct DashboardMaterialsSection: View {
    let summary: DashboardSummary

    var body: some View {
        Section("教材進捗") {
            if summary.appData.materials.isEmpty {
                ContentUnavailableView(
                    "教材が未登録です",
                    systemImage: "books.vertical",
                    description: Text("教材を登録すると、平均進捗と未完了教材を確認できます。")
                )
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("平均進捗")
                        Spacer()
                        Text("\(Int(summary.averageMaterialProgress))%")
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                    ProgressBar(value: summary.averageMaterialProgress / 100)
                }
                .padding(.vertical, 4)

                ForEach(summary.unfinishedMaterials.prefix(3)) { material in
                    DashboardMaterialRow(material: material)
                }
            }
        }
    }
}

struct DashboardWeaknessSection: View {
    let partSummaries: [DashboardPartSummary]

    var body: some View {
        Section("Part別の注意") {
            let focusedParts = partSummaries.filter { $0.priorityScore > 0 }.prefix(4)
            if focusedParts.isEmpty {
                ContentUnavailableView(
                    "弱点データがありません",
                    systemImage: "target",
                    description: Text("学習記録やミス理由を登録すると、Part別に注意点を表示します。")
                )
            } else {
                ForEach(Array(focusedParts)) { item in
                    DashboardPartRow(summary: item)
                }
            }
        }
    }
}

struct DashboardVocabularySection: View {
    let summary: DashboardSummary

    var body: some View {
        Section("語彙チェック") {
            if summary.appData.vocabularyItems.isEmpty {
                ContentUnavailableView(
                    "単語が未登録です",
                    systemImage: "textformat.abc",
                    description: Text("単語を登録すると、復習が必要な件数を確認できます。")
                )
            } else {
                HStack(spacing: 12) {
                    DashboardMetricTile(title: "○", value: "\(summary.vocabularyCircleCount)", systemImage: "checkmark.seal")
                    DashboardMetricTile(title: "△", value: "\(summary.vocabularyTriangleCount)", systemImage: "exclamationmark.circle")
                    DashboardMetricTile(title: "×", value: "\(summary.vocabularyCrossCount)", systemImage: "xmark.circle")
                }

                HStack {
                    Text("復習対象")
                    Spacer()
                    Text("\(summary.vocabularyNeedsReviewCount)/\(summary.appData.vocabularyItems.count)件")
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
            }
        }
    }
}

struct DashboardPremiumAnalyticsSection: View {
    var body: some View {
        Section("詳細分析") {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("Premium", systemImage: "chart.xyaxis.line")
                        .font(.headline)
                    Spacer()
                    TierBadge(tier: .premium)
                }

                Text("学習時間推移、Part別正答率、弱点の変化をここに追加予定です。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 6)
        }
    }
}

struct DashboardRecentLogsSection: View {
    let logs: [StudyLog]
    let materials: [Material]

    var body: some View {
        Section("最近の学習記録") {
            if logs.isEmpty {
                ContentUnavailableView(
                    "学習記録がありません",
                    systemImage: "square.and.pencil",
                    description: Text("学習を記録すると、直近の履歴がここに表示されます。")
                )
            } else {
                ForEach(logs) { log in
                    DashboardStudyLogRow(log: log, materialName: materialName(for: log.materialID))
                }
            }
        }
    }

    private func materialName(for id: EntityID?) -> String {
        guard let id, let material = materials.first(where: { $0.id == id }) else {
            return "教材未選択"
        }
        return material.name
    }
}

struct DashboardMetricTile: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(.teal)
            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct DashboardTagLine: View {
    let title: String
    let values: [String]

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(values.joined(separator: ", "))
                .font(.subheadline)
        }
    }
}

struct DashboardMaterialRow: View {
    let material: Material

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(material.name)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(Int(material.progressRate))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ProgressBar(value: material.progressRate / 100)
            HStack {
                Label("\(material.currentRound)/\(material.targetRounds)周", systemImage: "arrow.triangle.2.circlepath")
                Spacer()
                Text(material.targetParts.sorted { $0.number < $1.number }.map(\.title).joined(separator: ", "))
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct DashboardPartRow: View {
    let summary: DashboardPartSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(summary.part.title)
                        .font(.headline)
                    Text(summary.part.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if summary.isGoalWeakPart {
                    Label("重点", systemImage: "flag.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            HStack {
                Label("\(summary.totalMinutes)分", systemImage: "clock")
                Label("ミス\(summary.mistakeCount)", systemImage: "exclamationmark.triangle")
                if let accuracy = summary.averageAccuracyRate {
                    Label("\(Int(accuracy * 100))%", systemImage: "percent")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct DashboardStudyLogRow: View {
    let log: StudyLog
    let materialName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(log.part.title)
                    .font(.headline)
                Spacer()
                Text(log.studiedOn.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(materialName)
                .font(.subheadline)

            HStack {
                Label("\(log.minutes)分", systemImage: "clock")
                Label(log.understanding.title, systemImage: "checkmark.circle")
                if let accuracyRate = log.accuracyRate {
                    Label("\(Int(accuracyRate * 100))%", systemImage: "percent")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if !log.studyRange.isEmpty {
                Text(log.studyRange)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        DashboardPage()
            .environmentObject(AppDataStore())
    }
}
