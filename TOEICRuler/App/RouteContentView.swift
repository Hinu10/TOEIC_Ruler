import SwiftUI

struct RouteContentView: View {
    let route: AppRoute

    var body: some View {
        switch route {
        case .dashboard:
            PlaceholderPage(route: route, message: "学習状況の概要は Issue 10 で実装します。")
        case .today:
            PlaceholderPage(route: route, message: "今日の学習メニューは Issue 6 で実装します。")
        case .materials:
            MaterialsPage()
        case .studyLogs:
            StudyLogsPage()
        case .vocabulary:
            PlaceholderPage(route: route, message: "単語チェックは Issue 7 で実装します。")
        case .weaknesses:
            WeaknessPage()
        case .weaknessNotes:
            PlaceholderPage(route: route, message: "弱点ノートは Issue 9 で実装します。")
        case .goalSettings:
            GoalSettingsPage()
        }
    }
}
