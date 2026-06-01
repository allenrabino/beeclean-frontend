import SwiftUI

// MARK: - Leaderboard Row
//
// List row for ranks 4+. The current user's row lifts as a white card
// with a soft shadow; rank sits outside the card on the left.

struct LeaderboardRow: View {
    let entry: LeaderboardEntry

    var body: some View {
        if entry.isSelf {
            selfRow
        } else {
            standardRow
        }
    }

    // MARK: Standard

    private var standardRow: some View {
        HStack(spacing: 12) {
            rankLabel
            avatar
            Text(entry.displayName)
                .font(.labelMedium)
                .fontWeight(.semibold)
                .foregroundColor(.foreground)
                .lineLimit(1)
            Spacer(minLength: 8)
            statLabel
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(rowSurface)
    }

    // MARK: Self (elevated card)

    private var selfRow: some View {
        HStack(spacing: 10) {
            Text("\(entry.rank)")
                .font(.labelMedium)
                .foregroundColor(.mutedForeground)
                .frame(width: 24, alignment: .center)

            HStack(spacing: 12) {
                avatar
                Text(entry.displayName)
                    .font(.labelMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(.foreground)
                    .lineLimit(1)
                Spacer(minLength: 8)
                statLabel
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                    .fill(Color.card)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 6)
            .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
        }
    }

    // MARK: Shared

    private var rankLabel: some View {
        Text("\(entry.rank)")
            .font(.labelMedium)
            .foregroundColor(.mutedForeground)
            .frame(width: 24, alignment: .center)
    }

    private var avatar: some View {
        BeeAvatarView(equippedAssetIds: entry.equippedAccessoryIds, size: 36)
            .frame(width: 40, height: 40)
            .clipShape(Circle())
    }

    private var statLabel: some View {
        Text(LeaderboardFormatting.coins(entry.coins))
            .font(.bodySmall)
            .foregroundColor(.mutedForeground)
    }

    private var rowSurface: some View {
        RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
            .fill(Color.card)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                    .strokeBorder(Color.border.opacity(0.6), lineWidth: 0.5)
            )
    }
}
