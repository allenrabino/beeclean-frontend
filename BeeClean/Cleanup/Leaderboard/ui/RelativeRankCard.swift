import SwiftUI

// MARK: - Relative Rank Card (Quittr-style)
//
// Shows current rank, progress to the next rank, and distance to Top 100.

struct RelativeRankCard: View {
    let selfEntry: LeaderboardEntry?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            if let entry = selfEntry {
                rankRow(entry)
                progressSection(entry)
            } else {
                Text("Complete a cleanup to join the hive ladder.")
                    .font(.bodySmall)
                    .foregroundColor(.mutedForeground)
            }
        }
        .padding(16)
        .background(cardBackground)
    }

    @ViewBuilder
    private var cardBackground: some View {
        if let entry = selfEntry, entry.inTop100 {
            LeaderboardGlassRowBackground(isSelf: entry.isSelf, cornerRadius: DesignTokens.Radius.xl)
        } else {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.xl, style: .continuous)
                .fill(Color.card)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.xl, style: .continuous)
                        .strokeBorder(Color.border, lineWidth: 0.5)
                )
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .foregroundStyle(LinearGradient.honeyGradient)
            Text("Your Rank")
                .font(.titleSmall)
                .foregroundColor(.foreground)
            Spacer()
            if let entry = selfEntry, entry.inTop100 {
                Text("TOP 100")
                    .font(.labelSmall)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color(hex: "D4A01C")))
            }
        }
    }

    private func rankRow(_ entry: LeaderboardEntry) -> some View {
        HStack(spacing: 12) {
            ZStack {
                LeaderboardPlaceholderAvatar(entry: entry, size: 56)
                if entry.inTop100 {
                    LeaderboardGlassAvatarRing(isSelf: true)
                }
            }
            .frame(width: 64, height: 64)
            VStack(alignment: .leading, spacing: 4) {
                Text("#\(entry.rank) · \(entry.displayName)")
                    .font(.labelMedium)
                    .foregroundColor(.foreground)
                HStack(spacing: 4) {
                    Image(systemName: "bitcoinsign.circle.fill")
                        .foregroundStyle(LinearGradient.honeyGradient)
                    Text("\(entry.coins) coins")
                        .font(.bodySmall)
                        .foregroundColor(.mutedForeground)
                }
            }
            Spacer()
        }
    }

    @ViewBuilder
    private func progressSection(_ entry: LeaderboardEntry) -> some View {
        if entry.inTop100 {
            Label("You're in the Top 100 — keep climbing!", systemImage: "trophy.fill")
                .font(.bodySmall)
                .foregroundColor(.mutedForeground)
        } else if let coinsToTop100 = entry.coinsToTop100, coinsToTop100 > 0 {
            progressBar(
                title: "Coins to Top 100",
                detail: "\(coinsToTop100) more coins",
                progress: min(1, max(0, 1 - Double(coinsToTop100) / Double(max(entry.coins + coinsToTop100, 1))))
            )
        }

        if let coinsToNext = entry.coinsToNextRank, coinsToNext > 0, entry.rank > 1 {
            progressBar(
                title: "Next rank up",
                detail: "\(coinsToNext) coins to pass #\(max(1, entry.rank - 1))",
                progress: entry.progressToNextRank
            )
        }
    }

    private func progressBar(title: String, detail: String, progress: Double) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.labelMedium)
                    .foregroundColor(.foreground)
                Spacer()
                Text(detail)
                    .font(.bodySmall)
                    .foregroundColor(.mutedForeground)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.surfaceLight)
                    Capsule()
                        .fill(LinearGradient.honeyGradient)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 8)
        }
    }
}
