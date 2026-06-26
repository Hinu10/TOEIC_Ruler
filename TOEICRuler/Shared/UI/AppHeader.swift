import SwiftUI

struct AppHeader: View {
    let title: String
    let route: AppRoute?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                if let route {
                    Image(systemName: route.systemImage)
                        .font(.title3)
                        .foregroundStyle(.teal)
                }

                Text(title)
                    .font(.title2.weight(.semibold))
                    .lineLimit(2)

                Spacer(minLength: 12)

                if let route, route.tier == .premium {
                    TierBadge(tier: route.tier)
                }
            }

            Divider()
        }
    }
}
