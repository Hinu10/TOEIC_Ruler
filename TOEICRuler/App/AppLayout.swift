import SwiftUI

struct AppLayout: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selectedRoute: AppRoute = .dashboard
    @State private var selectedTab: AppTab = .dashboard

    var body: some View {
        Group {
            if horizontalSizeClass == .compact {
                CompactTabLayout(selectedTab: $selectedTab)
            } else {
                SidebarLayout(selectedRoute: $selectedRoute)
            }
        }
    }
}

private struct SidebarLayout: View {
    @Binding var selectedRoute: AppRoute

    var body: some View {
        NavigationSplitView {
            AppNavigationSidebar(selectedRoute: $selectedRoute)
        } detail: {
            NavigationStack {
                RouteContentView(route: selectedRoute)
            }
        }
    }
}

private struct CompactTabLayout: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(AppTab.primaryTabs) { tab in
                NavigationStack {
                    RouteContentView(route: tab.route)
                }
                .tabItem {
                    Label(tab.title, systemImage: tab.systemImage)
                }
                .tag(tab)
            }

            NavigationStack {
                MoreRoutesPage()
            }
            .tabItem {
                Label("その他", systemImage: "ellipsis.circle")
            }
            .tag(AppTab.more)
        }
    }
}
