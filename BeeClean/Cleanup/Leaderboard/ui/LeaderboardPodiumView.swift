import SwiftUI

// MARK: - Leaderboard Podium
//
// Top 3 in a light podium layout: 2nd left, 1st center (tallest),
// 3rd right. Gold, silver, and bronze avatar rings with rank badges.

struct LeaderboardPodiumView: View {
    enum Style {
        case full
        case compact
    }

    let entries: [LeaderboardEntry]
    var style: Style = .full
    var onSelect: ((LeaderboardEntry) -> Void)?

    var body: some View {
        HStack(alignment: .bottom, spacing: style == .full ? 20 : 12) {
            if entries.count >= 2 {
                podiumColumn(entries[1], place: 2)
            }
            if entries.count >= 1 {
                podiumColumn(entries[0], place: 1)
                    .offset(y: style == .full ? -12 : -8)
            }
            if entries.count >= 3 {
                podiumColumn(entries[2], place: 3)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, style == .full ? 8 : 4)
        .padding(.bottom, style == .full ? 4 : 2)
    }

    // MARK: Column

    private func podiumColumn(_ entry: LeaderboardEntry, place: Int) -> some View {
        let theme = PodiumMedalTheme(place: place)
        let avatarSize: CGFloat = switch (style, place) {
        case (.full, 1): 88
        case (.full, _): 72
        case (.compact, 1): 56
        case (.compact, _): 46
        }
        let ringWidth: CGFloat = style == .full ? 3.5 : 2.5
        let badgeSize: CGFloat = style == .full ? 24 : 18

        let innerSize = avatarSize - ringWidth * 2

        return VStack(spacing: style == .full ? 10 : 6) {
            ZStack(alignment: .bottom) {
                ZStack {
                    Circle()
                        .strokeBorder(theme.ringGradient, lineWidth: ringWidth)
                        .frame(width: avatarSize, height: avatarSize)
                    BeeAvatarView(equippedAssetIds: entry.equippedAccessoryIds, size: innerSize)
                        .frame(width: innerSize, height: innerSize)
                        .clipShape(Circle())
                }

                Text("\(place)")
                    .font(.system(size: style == .full ? 12 : 10, weight: .bold))
                    .foregroundColor(theme.badgeText)
                    .frame(width: badgeSize, height: badgeSize)
                    .background(Circle().fill(theme.badgeFill))
                    .overlay(Circle().strokeBorder(theme.badgeStroke, lineWidth: 0.5))
                    .offset(y: badgeSize / 2 - 2)
            }
            .frame(width: avatarSize, height: avatarSize + badgeSize / 2)

            Text(entry.displayName)
                .font(style == .full ? .labelMedium : .labelSmall)
                .fontWeight(.semibold)
                .foregroundColor(.foreground)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            LeaderboardEntryStats(entry: entry, layout: style == .full ? .podium : .podiumCompact)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { onSelect?(entry) }
    }
}

// MARK: - Medal Theme

private struct PodiumMedalTheme {
    let place: Int

    var ringGradient: LinearGradient {
        switch place {
        case 1:
            return LinearGradient(
                colors: [Color(hex: "FFE566"), Color(hex: "D4A01C"), Color(hex: "A87408")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case 2:
            return LinearGradient(
                colors: [Color(hex: "F0F0F2"), Color(hex: "B0B6BA"), Color(hex: "8A9096")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [Color(hex: "E8A86B"), Color(hex: "B87333"), Color(hex: "8B5A2B")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    var badgeFill: Color {
        switch place {
        case 1: return Color(hex: "D4A01C")
        case 2: return Color(hex: "9CA3AF")
        default: return Color(hex: "B87333")
        }
    }

    var badgeStroke: Color {
        switch place {
        case 1: return Color(hex: "A87408").opacity(0.5)
        case 2: return Color(hex: "6B7280").opacity(0.4)
        default: return Color(hex: "8B5A2B").opacity(0.45)
        }
    }

    var badgeText: Color {
        place == 2 ? Color(hex: "1C1917") : .white
    }
}

// MARK: - Formatting

enum LeaderboardFormatting {
    static func coins(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    static func storageFreed(_ valueGB: Double) -> String {
        let display = storageDisplay(valueGB)
        return "\(display.value) \(display.unit)"
    }

    static func storageDisplay(_ valueGB: Double) -> (value: String, unit: String) {
        let hasFraction = abs(valueGB.truncatingRemainder(dividingBy: 1)) >= 0.05
        let value = hasFraction ? String(format: "%.1f", valueGB) : String(format: "%.0f", valueGB)
        return (value, "GB")
    }
}

// MARK: - Entry Stats

struct LeaderboardEntryStats: View {
    enum Layout {
        case podium
        case podiumCompact
        case row
    }

    let entry: LeaderboardEntry
    var layout: Layout = .row

    var body: some View {
        switch layout {
        case .podium, .podiumCompact:
            VStack(spacing: layout == .podium ? 6 : 4) {
                coinsStat(font: layout == .podium ? .bodySmall : .labelSmall)
                storageStat(font: layout == .podium ? .bodySmall : .labelSmall)
            }
        case .row:
            VStack(alignment: .trailing, spacing: 4) {
                coinsStat(font: .bodySmall)
                storageStat(font: .labelSmall)
            }
        }
    }

    private func coinsStat(font: Font) -> some View {
        statLine(
            symbol: "bitcoinsign.circle.fill",
            text: LeaderboardFormatting.coins(entry.coins),
            font: font
        )
    }

    private func storageStat(font: Font) -> some View {
        let storage = LeaderboardFormatting.storageDisplay(entry.storageFreedGB)

        return HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(storage.value)
                .font(font)
                .fontWeight(.semibold)
                .foregroundColor(.foreground.opacity(0.78))
                .monospacedDigit()
            Text(storage.unit)
                .font(.system(size: unitSize(for: font), weight: .medium))
                .foregroundColor(.mutedForeground)
        }
        .padding(.horizontal, storagePadding.horizontal)
        .padding(.vertical, storagePadding.vertical)
        .background(
            Capsule(style: .continuous)
                .fill(Color.secondaryColor.opacity(0.08))
        )
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(Color.secondaryColor.opacity(0.14), lineWidth: 0.5)
        )
    }

    private var storagePadding: (horizontal: CGFloat, vertical: CGFloat) {
        switch layout {
        case .podium: return (10, 4)
        case .podiumCompact: return (8, 3)
        case .row: return (8, 3)
        }
    }

    private func unitSize(for font: Font) -> CGFloat {
        switch layout {
        case .podium: return 11
        case .podiumCompact: return 9
        case .row: return 10
        }
    }

    private func statLine(symbol: String, text: String, font: Font) -> some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundColor(.mutedForeground)
            Text(text)
                .font(font)
                .foregroundColor(.mutedForeground)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    private var iconSize: CGFloat {
        switch layout {
        case .podium: return 11
        case .podiumCompact: return 9
        case .row: return 10
        }
    }
}

#Preview("Full Podium") {
    LeaderboardPodiumView(
        entries: [
            LeaderboardEntry(id: "1", rank: 1, displayName: "Andrew Miller", coins: 9792, storageFreedGB: 87.8, streak: 12, equippedAccessoryIds: ["hat_royal_honey_crown"], isSelf: false),
            LeaderboardEntry(id: "2", rank: 2, displayName: "Harper Davis", coins: 9717, storageFreedGB: 86.9, streak: 8, equippedAccessoryIds: ["glasses_wayfarer"], isSelf: false),
            LeaderboardEntry(id: "3", rank: 3, displayName: "David Collins", coins: 9613, storageFreedGB: 85.9, streak: 5, equippedAccessoryIds: [], isSelf: false),
        ],
        style: .full
    )
    .padding()
    .background(Color.background)
}

#Preview("Compact Podium") {
    LeaderboardPodiumView(
        entries: [
            LeaderboardEntry(id: "1", rank: 1, displayName: "Andrew Miller", coins: 9792, storageFreedGB: 87.8, streak: 12, equippedAccessoryIds: ["hat_royal_honey_crown"], isSelf: false),
            LeaderboardEntry(id: "2", rank: 2, displayName: "Harper Davis", coins: 9717, storageFreedGB: 86.9, streak: 8, equippedAccessoryIds: ["glasses_wayfarer"], isSelf: false),
            LeaderboardEntry(id: "3", rank: 3, displayName: "David Collins", coins: 9613, storageFreedGB: 85.9, streak: 5, equippedAccessoryIds: [], isSelf: false),
        ],
        style: .compact
    )
    .padding()
    .background(Color.card)
}
