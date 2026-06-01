import SwiftUI

// MARK: - Leaderboard Podium
//
// Olympic-style three-tier trophy board: 2nd left, 1st center (tallest),
// 3rd right. Dark stage, glowing rings, SF Symbol medals, score pills.

struct LeaderboardPodiumView: View {
    enum Style {
        case full
        case compact
    }

    let entries: [LeaderboardEntry]
    var style: Style = .full
    var onSelect: ((LeaderboardEntry) -> Void)?

    var body: some View {
        ZStack {
            stageBackground

            HStack(alignment: .bottom, spacing: style == .full ? 8 : 4) {
                if entries.count >= 2 {
                    podiumColumn(entries[1], place: 2)
                }
                if entries.count >= 1 {
                    podiumColumn(entries[0], place: 1)
                }
                if entries.count >= 3 {
                    podiumColumn(entries[2], place: 3)
                }
            }
            .padding(.horizontal, style == .full ? 10 : 6)
            .padding(.top, style == .full ? 28 : 18)
            .padding(.bottom, style == .full ? 14 : 10)
        }
    }

    // MARK: Stage

    private var stageBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: stageCornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "232328"), Color(hex: "141416")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "D4A01C").opacity(style == .full ? 0.22 : 0.16),
                            Color(hex: "D4A01C").opacity(0.05),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 8,
                        endRadius: style == .full ? 140 : 90
                    )
                )
                .frame(width: style == .full ? 280 : 200, height: style == .full ? 180 : 120)
                .offset(y: style == .full ? -30 : -18)

            RoundedRectangle(cornerRadius: stageCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.025))
                .blendMode(.overlay)
        }
        .overlay(
            RoundedRectangle(cornerRadius: stageCornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.14),
                            Color.white.opacity(0.04),
                            Color.black.opacity(0.25)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(style == .full ? 0.28 : 0.14), radius: style == .full ? 24 : 12, y: style == .full ? 12 : 6)
    }

    private var stageCornerRadius: CGFloat {
        style == .full ? DesignTokens.Radius.xl : DesignTokens.Radius.lg
    }

    // MARK: Column

    private func podiumColumn(_ entry: LeaderboardEntry, place: Int) -> some View {
        let theme = PodiumTheme(place: place, style: style)

        return VStack(spacing: style == .full ? 8 : 4) {
            avatarRing(entry: entry, theme: theme)
            nameRow(entry: entry, theme: theme)
            scorePill(coins: entry.coins, theme: theme)
            pedestal(place: place, theme: theme)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { onSelect?(entry) }
    }

    private func avatarRing(entry: LeaderboardEntry, theme: PodiumTheme) -> some View {
        let avatarSize: CGFloat = switch style {
        case .full: theme.place == 1 ? 54 : 46
        case .compact: theme.place == 1 ? 38 : 32
        }
        let ringSize = avatarSize + (style == .full ? 8 : 6)

        return ZStack {
            if theme.place == 1 {
                Circle()
                    .fill(theme.ringGlow)
                    .frame(width: ringSize + (style == .full ? 16 : 10), height: ringSize + (style == .full ? 16 : 10))
                    .blur(radius: style == .full ? 10 : 6)
            }

            Circle()
                .strokeBorder(theme.ringGradient, lineWidth: style == .full ? 3 : 2)
                .frame(width: ringSize, height: ringSize)
                .shadow(color: theme.ringShadow, radius: theme.place == 1 ? 6 : 3)

            Circle()
                .fill(Color(hex: "1E1E22"))
                .frame(width: avatarSize, height: avatarSize)

            BeeAvatarView(equippedAssetIds: entry.equippedAccessoryIds, size: avatarSize)
                .frame(width: avatarSize, height: avatarSize)
                .clipShape(Circle())
        }
        .frame(width: ringSize, height: ringSize)
    }

    private func nameRow(entry: LeaderboardEntry, theme: PodiumTheme) -> some View {
        HStack(spacing: 3) {
            Text(entry.displayName)
                .font(style == .full ? .labelMedium : .labelSmall)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            medalIcon(theme: theme)
        }
        .frame(maxWidth: .infinity)
    }

    private func medalIcon(theme: PodiumTheme) -> some View {
        Image(systemName: theme.medalSymbol)
            .font(.system(size: style == .full ? 11 : 9, weight: .bold))
            .foregroundStyle(theme.medalColor)
            .frame(width: style == .full ? 14 : 12, height: style == .full ? 14 : 12)
    }

    private func scorePill(coins: Int, theme: PodiumTheme) -> some View {
        Text(LeaderboardFormatting.coins(coins))
            .font(style == .full ? .labelMedium : .labelSmall)
            .fontWeight(.bold)
            .foregroundColor(theme.pillText)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, style == .full ? 12 : 7)
            .padding(.vertical, style == .full ? 5 : 3)
            .background(Capsule(style: .continuous).fill(theme.pillFill))
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(theme.pillStroke, lineWidth: 0.5)
            )
    }

    private func pedestal(place: Int, theme: PodiumTheme) -> some View {
        let height: CGFloat = switch (style, place) {
        case (.full, 1): 96
        case (.full, 2): 72
        case (.full, 3): 56
        case (.compact, 1): 48
        case (.compact, 2): 36
        case (.compact, 3): 28
        default: 44
        }

        let shape = UnevenRoundedRectangle(
            topLeadingRadius: style == .full ? DesignTokens.Radius.md : DesignTokens.Radius.sm,
            bottomLeadingRadius: 3,
            bottomTrailingRadius: 3,
            topTrailingRadius: style == .full ? DesignTokens.Radius.md : DesignTokens.Radius.sm,
            style: .continuous
        )

        return ZStack {
            shape.fill(theme.pedestalGradient)
            shape.fill(
                LinearGradient(
                    colors: [Color.white.opacity(0.12), Color.clear],
                    startPoint: .top,
                    endPoint: .center
                )
            )
            Text("\(place)")
                .font(.system(size: style == .full ? 44 : 24, weight: .bold, design: .rounded))
                .foregroundColor(Color.white.opacity(0.22))
                .offset(y: style == .full ? 6 : 3)
        }
        .frame(height: height)
        .overlay(shape.strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5))
    }
}

// MARK: - Podium Theme

private struct PodiumTheme {
    let place: Int
    let style: LeaderboardPodiumView.Style

    var medalSymbol: String {
        switch place {
        case 1: return "crown.fill"
        default: return "medal.fill"
        }
    }

    var medalColor: Color {
        switch place {
        case 1: return Color(hex: "F5C842")
        case 2: return Color(hex: "C8CDD1")
        default: return Color(hex: "C48655")
        }
    }

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

    var ringGlow: Color {
        place == 1 ? Color(hex: "D4A01C").opacity(0.55) : .clear
    }

    var ringShadow: Color {
        switch place {
        case 1: return Color(hex: "D4A01C").opacity(0.5)
        case 2: return Color(hex: "B0B6BA").opacity(0.35)
        default: return Color(hex: "B87333").opacity(0.35)
        }
    }

    var pillFill: Color {
        switch place {
        case 1: return Color(hex: "F5C842")
        case 2: return Color(hex: "D8DDE0")
        default: return Color(hex: "E8A86B")
        }
    }

    var pillStroke: Color {
        switch place {
        case 1: return Color(hex: "C4920A").opacity(0.4)
        case 2: return Color.white.opacity(0.5)
        default: return Color(hex: "8B5A2B").opacity(0.35)
        }
    }

    var pillText: Color {
        Color(hex: "1C1917")
    }

    var pedestalGradient: LinearGradient {
        switch place {
        case 1:
            return LinearGradient(
                colors: [Color(hex: "6B5A28"), Color(hex: "3D3418")],
                startPoint: .top,
                endPoint: .bottom
            )
        case 2:
            return LinearGradient(
                colors: [Color(hex: "4A4D52"), Color(hex: "2A2C30")],
                startPoint: .top,
                endPoint: .bottom
            )
        default:
            return LinearGradient(
                colors: [Color(hex: "5C4030"), Color(hex: "352820")],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

// MARK: - Formatting

enum LeaderboardFormatting {
    static func coins(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

#Preview("Full Podium") {
    LeaderboardPodiumView(
        entries: [
            LeaderboardEntry(id: "1", rank: 1, displayName: "QueenBee", coins: 9792, storageFreedGB: 87.8, streak: 12, equippedAccessoryIds: ["hat_royal_honey_crown"], isSelf: false),
            LeaderboardEntry(id: "2", rank: 2, displayName: "HoneyHive", coins: 9717, storageFreedGB: 86.9, streak: 8, equippedAccessoryIds: ["glasses_wayfarer"], isSelf: false),
            LeaderboardEntry(id: "3", rank: 3, displayName: "BuzzMaster", coins: 9613, storageFreedGB: 85.9, streak: 5, equippedAccessoryIds: [], isSelf: false),
        ],
        style: .full
    )
    .padding()
    .background(Color.background)
}

#Preview("Compact Podium") {
    LeaderboardPodiumView(
        entries: [
            LeaderboardEntry(id: "1", rank: 1, displayName: "QueenBee", coins: 9792, storageFreedGB: 87.8, streak: 12, equippedAccessoryIds: ["hat_royal_honey_crown"], isSelf: false),
            LeaderboardEntry(id: "2", rank: 2, displayName: "HoneyHive", coins: 9717, storageFreedGB: 86.9, streak: 8, equippedAccessoryIds: ["glasses_wayfarer"], isSelf: false),
            LeaderboardEntry(id: "3", rank: 3, displayName: "BuzzMaster", coins: 9613, storageFreedGB: 85.9, streak: 5, equippedAccessoryIds: [], isSelf: false),
        ],
        style: .compact
    )
    .padding()
    .background(Color.card)
}
