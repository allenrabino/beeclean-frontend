import SwiftUI

// MARK: - Leaderboard Row
//
// Single ladder row outside the podium. Top 100 bees get a glass-polish
// treatment — frosted surface, specular rim, and a polished avatar ring.

struct LeaderboardRow: View {
    let entry: LeaderboardEntry

    private var isGlassPolished: Bool { entry.inTop100 }

    var body: some View {
        HStack(spacing: 12) {
            Text("#\(entry.rank)")
                .font(.labelMedium)
                .foregroundColor(isGlassPolished ? .foreground.opacity(0.7) : .mutedForeground)
                .frame(width: 38, alignment: .leading)

            avatar

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.displayName)
                    .font(.labelMedium)
                    .foregroundColor(.foreground)
                HStack(spacing: 4) {
                    Image(systemName: "externaldrive.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.mutedForeground)
                    Text(String(format: "%.1f GB", entry.storageFreedGB))
                        .font(.bodySmall)
                        .foregroundColor(.mutedForeground)
                }
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "bitcoinsign.circle.fill")
                    .foregroundStyle(LinearGradient.honeyGradient)
                Text(LeaderboardFormatting.coins(entry.coins))
                    .font(.titleSmall)
                    .foregroundColor(.foreground)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(rowBackground)
    }

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(
                    isGlassPolished
                        ? Color(hex: "1E1E22").opacity(0.08)
                        : (entry.isSelf ? Color.accentColor.opacity(0.18) : Color.surfaceLight)
                )
            BeeAvatarView(equippedAssetIds: entry.equippedAccessoryIds, size: 32)
            if isGlassPolished {
                LeaderboardGlassAvatarRing(isSelf: entry.isSelf)
            }
        }
        .frame(width: 40, height: 40)
        .clipShape(Circle())
    }

    @ViewBuilder
    private var rowBackground: some View {
        if isGlassPolished {
            LeaderboardGlassRowBackground(isSelf: entry.isSelf)
        } else {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                .fill(entry.isSelf ? Color.accentColor.opacity(0.08) : Color.card)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                        .strokeBorder(
                            entry.isSelf ? Color.accentColor : Color.border,
                            lineWidth: entry.isSelf ? 1.5 : 0.5
                        )
                )
        }
    }
}
