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
