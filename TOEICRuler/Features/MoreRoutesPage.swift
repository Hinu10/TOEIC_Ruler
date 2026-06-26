import SwiftUI

struct MoreRoutesPage: View {
    private let routes = AppRoute.allCases.filter { route in
        !AppTab.primaryTabs.map(\.route).contains(route)
    }

    var body: some View {
        PageContainer(title: "その他", route: nil) {
            List(routes) { route in
                NavigationLink(value: route) {
                    HStack(spacing: 12) {
                        Image(systemName: route.systemImage)
                            .frame(width: 24)
                            .foregroundStyle(.teal)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(route.title)
                                .font(.body)
                            Text(route.tier.title)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if route.tier == .premium {
                            TierBadge(tier: route.tier)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.plain)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .navigationDestination(for: AppRoute.self) { route in
            RouteContentView(route: route)
        }
    }
}
