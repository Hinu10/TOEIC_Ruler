import SwiftUI

struct RouteContentView: View {
    let route: AppRoute

    var body: some View {
        switch route {
        case .dashboard:
            DashboardPage()
        case .today:
            TodayPage()
        case .materials:
            MaterialsPage()
        case .studyLogs:
            StudyLogsPage()
        case .vocabulary:
            VocabularyPage()
        case .weaknesses:
            WeaknessPage()
        case .weaknessNotes:
            WeaknessNotebookPage()
        case .goalSettings:
            GoalSettingsPage()
        }
    }
}
