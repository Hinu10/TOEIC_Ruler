import Foundation

enum AppRoute: String, CaseIterable, Identifiable, Codable, Hashable {
    case dashboard
    case today
    case materials
    case studyLogs
    case vocabulary
    case weaknesses
    case weaknessNotes
    case goalSettings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: "ダッシュボード"
        case .today: "今日の学習"
        case .materials: "教材"
        case .studyLogs: "学習記録"
        case .vocabulary: "単語チェック"
        case .weaknesses: "弱点管理"
        case .weaknessNotes: "弱点ノート"
        case .goalSettings: "目標設定"
        }
    }

    var tier: FeatureTier {
        switch self {
        case .weaknessNotes:
            .premium
        default:
            .free
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard: "chart.bar.doc.horizontal"
        case .today: "calendar.badge.clock"
        case .materials: "books.vertical"
        case .studyLogs: "square.and.pencil"
        case .vocabulary: "textformat.abc"
        case .weaknesses: "target"
        case .weaknessNotes: "note.text"
        case .goalSettings: "flag.checkered"
        }
    }
}
