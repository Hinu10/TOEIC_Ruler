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
            PlaceholderPage(route: route, message: "教材管理は Issue 4 で実装します。")
        case .studyLogs:
            PlaceholderPage(route: route, message: "学習記録は Issue 5 で実装します。")
        case .vocabulary:
            PlaceholderPage(route: route, message: "単語チェックは Issue 7 で実装します。")
        case .weaknesses:
            PlaceholderPage(route: route, message: "弱点管理は Issue 8 で実装します。")
        case .weaknessNotes:
            PlaceholderPage(route: route, message: "弱点ノートは Issue 9 で実装します。")
        case .goalSettings:
            PlaceholderPage(route: route, message: "目標設定は Issue 3 で実装します。")
        }
    }
}
