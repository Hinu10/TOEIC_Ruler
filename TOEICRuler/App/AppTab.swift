import Foundation

enum AppTab: String, CaseIterable, Identifiable, Hashable {
    case dashboard
    case today
    case materials
    case studyLogs
    case more

    var id: String { rawValue }

    static let primaryTabs: [AppTab] = [
        .dashboard,
        .today,
        .materials,
        .studyLogs
    ]

    var route: AppRoute {
        switch self {
        case .dashboard: .dashboard
        case .today: .today
        case .materials: .materials
        case .studyLogs: .studyLogs
        case .more: .dashboard
        }
    }

    var title: String {
        switch self {
        case .more:
            "その他"
        default:
            route.title
        }
    }

    var systemImage: String {
        switch self {
        case .more:
            "ellipsis.circle"
        default:
            route.systemImage
        }
    }
}
