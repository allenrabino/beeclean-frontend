import SwiftUI

// MARK: - Leaderboard Preview Card
//
// Compact leaderboard surface rendered on the Progress tab. Shows the
// top 3 on a mini trophy podium, the user's own row, and a CTA
// to push into the full LeaderboardView.

struct LeaderboardPreviewCard: View {
    @StateObject private var vm = LeaderboardViewModel.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            NavigationLink {
                LeaderboardView()
                    .hidesBottomNavBar()
            } label: {
                LeaderboardPodiumView(
                    entries: Array(vm.entries.prefix(3)),
                    style: .compact
                )
            }
            .buttonStyle(.plain)

            if let me = vm.selfEntry {
                Divider().opacity(0.5)
                LeaderboardRow(entry: me)
            }

            seeAllButton
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.xl, style: .continuous)
                .fill(Color.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.xl, style: .continuous)
                .strokeBorder(Color.border, lineWidth: 0.5)
        )
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(LinearGradient.honeyGradient)
            VStack(alignment: .leading, spacing: 2) {
                Text("Leaderboard")
                    .font(.titleSmall)
                    .foregroundColor(.foreground)
                Text("Ranked by coins · storage freed shown alongside")
                    .font(.bodySmall)
                    .foregroundColor(.mutedForeground)
            }
            Spacer()
        }
    }

    private var seeAllButton: some View {
        NavigationLink {
            LeaderboardView()
                .hidesBottomNavBar()
        } label: {
            HStack {
                Text("See full leaderboard")
                    .font(.labelMedium)
                    .foregroundColor(.foreground)
                Spacer()
                ChevronGlyph()
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                    .fill(Color.surfaceLight)
            )
        }
        .simultaneousGesture(TapGesture().onEnded {
            HapticManager.shared.buttonTap()
        })
        .buttonStyle(.plain)
    }
}
