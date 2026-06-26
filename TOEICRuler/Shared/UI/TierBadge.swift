import SwiftUI

struct TierBadge: View {
    let tier: FeatureTier

    var body: some View {
        Text(tier.title)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(tier == .premium ? .indigo : .secondary)
            .background(
                Capsule()
                    .fill(tier == .premium ? Color.indigo.opacity(0.12) : Color.gray.opacity(0.14))
            )
    }
}
