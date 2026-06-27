import SwiftUI

struct RouteContentView: View {
    let route: AppRoute

    var body: some View {
        switch route {
        case .dashboard:
            PlaceholderPage(route: route, message: "学習状況の概要は Issue 10 で実装します。")
        case .today:
            TodayPage()
        case .materials:
            MaterialsPage()
        case .studyLogs:
            StudyLogsPage()
        case .vocabulary:
            VocabularyPage()
        case .weaknesses:
            PlaceholderPage(route: route, message: "弱点管理は Issue 8 で実装します。")
        case .weaknessNotes:
            PlaceholderPage(route: route, message: "弱点ノートは Issue 9 で実装します。")
        case .goalSettings:
            GoalSettingsPage()
        }
    }
}
