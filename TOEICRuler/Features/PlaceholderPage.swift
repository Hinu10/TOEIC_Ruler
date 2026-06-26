import SwiftUI

struct PlaceholderPage: View {
    let route: AppRoute
    let message: String

    var body: some View {
        PageContainer(title: route.title, route: route) {
            EmptyStateView(
                title: route.title,
                systemImage: route.systemImage,
                message: message
            )
        }
    }
}
