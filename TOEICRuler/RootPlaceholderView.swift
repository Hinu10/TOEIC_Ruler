import SwiftUI

struct RootPlaceholderView: View {
    @StateObject private var store = AppDataStore()

    var body: some View {
        NavigationStack {
            List(AppRoute.allCases) { route in
                NavigationLink(route.title, value: route)
            }
            .navigationDestination(for: AppRoute.self) { route in
                destination(for: route)
            }
            .navigationTitle("TOEIC Ruler")
        }
        .environmentObject(store)
    }

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .materials:
            MaterialsPage()
        case .goalSettings:
            GoalSettingsPage()
        default:
            PlaceholderScreen(route: route)
        }
    }
}

private struct PlaceholderScreen: View {
    let route: AppRoute

    var body: some View {
        ContentUnavailableView(
            route.title,
            systemImage: route.systemImage,
            description: Text("この画面は後続 Issue で実装します。")
        )
        .navigationTitle(route.title)
    }
}

#Preview {
    RootPlaceholderView()
}
