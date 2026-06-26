import SwiftUI

struct RootPlaceholderView: View {
    var body: some View {
        NavigationStack {
            List(AppRoute.allCases) { route in
                NavigationLink(route.title, value: route)
            }
            .navigationDestination(for: AppRoute.self) { route in
                PlaceholderScreen(route: route)
            }
            .navigationTitle("TOEIC Ruler")
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
