import SwiftUI

struct AppNavigationSidebar: View {
    @Binding var selectedRoute: AppRoute

    var body: some View {
        List(AppRoute.allCases, selection: $selectedRoute) { route in
            NavigationLink(value: route) {
                HStack(spacing: 12) {
                    Image(systemName: route.systemImage)
                        .frame(width: 22)
                        .foregroundStyle(.teal)

                    Text(route.title)

                    Spacer()

                    if route.tier == .premium {
                        TierBadge(tier: route.tier)
                    }
                }
            }
        }
        .navigationTitle("TOEIC Ruler")
    }
}
