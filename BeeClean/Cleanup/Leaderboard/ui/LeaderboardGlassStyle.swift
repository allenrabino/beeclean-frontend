import SwiftUI

// MARK: - Leaderboard Glass Polish
//
// Frosted glass surface for Top 100 hive members — specular rim,
// soft material fill, and a polished avatar ring.

struct LeaderboardGlassRowBackground: View {
    var isSelf: Bool
    var cornerRadius: CGFloat = DesignTokens.Radius.md

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        ZStack {
            shape.fill(Color.card.opacity(isSelf ? 0.78 : 0.65))
                .background(.ultraThinMaterial, in: shape)

            shape.fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.14),
                        Color.white.opacity(0.03),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            shape.strokeBorder(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.55),
                        Color.white.opacity(0.12),
                        Color.white.opacity(0.04)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )

            if isSelf {
                shape.strokeBorder(Color.accentColor.opacity(0.65), lineWidth: 1.5)
            }
        }
        .shadow(color: Color.black.opacity(0.06), radius: 8, y: 3)
        .shadow(color: Color.white.opacity(0.08), radius: 1, y: -0.5)
    }
}

struct LeaderboardGlassAvatarRing: View {
    var isSelf: Bool

    var body: some View {
        Circle()
            .strokeBorder(
                LinearGradient(
                    colors: isSelf
                        ? [Color(hex: "FFE566"), Color(hex: "D4A01C"), Color(hex: "A87408")]
                        : [Color.white.opacity(0.75), Color.white.opacity(0.25), Color.white.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: isSelf ? 2 : 1.5
            )
            .shadow(color: isSelf ? Color(hex: "D4A01C").opacity(0.35) : Color.white.opacity(0.15), radius: 3)
    }
}

// MARK: - Placeholder Avatar
//
// Colorful circle for ranked users on the ladder (list + podium). Stable
// per `entry.id` so colors don't flicker. Real bee + accessories live on
// `LeaderboardDetailView` after tap.

enum LeaderboardAvatarPalette {
    private static let pairs: [(String, String)] = [
        ("FF6B6B", "EE5A24"),
        ("4ECDC4", "2E86AB"),
        ("A29BFE", "6C5CE7"),
        ("FD79A8", "E84393"),
        ("FDCB6E", "E17055"),
        ("55EFC4", "00B894"),
        ("74B9FF", "0984E3"),
        ("FAB1A0", "D63031"),
        ("81ECEC", "00CEC9"),
        ("FFEAA7", "F39C12"),
        ("DFE6E9", "636E72"),
        ("FF9FF3", "F368E0"),
    ]

    static func gradient(for entryId: String) -> LinearGradient {
        let index = stableIndex(entryId, count: pairs.count)
        let pair = pairs[index]
        return LinearGradient(
            colors: [Color(hex: pair.0), Color(hex: pair.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private static func stableIndex(_ id: String, count: Int) -> Int {
        guard count > 0 else { return 0 }
        var hash = 0
        for byte in id.utf8 {
            hash = (hash &* 31 &+ Int(byte)) % count
        }
        return abs(hash) % count
    }
}

struct LeaderboardPlaceholderAvatar: View {
    let entry: LeaderboardEntry
    var size: CGFloat

    var body: some View {
        Circle()
            .fill(LeaderboardAvatarPalette.gradient(for: entry.id))
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .strokeBorder(Color.white.opacity(0.28), lineWidth: max(1, size * 0.04))
            )
    }
}
