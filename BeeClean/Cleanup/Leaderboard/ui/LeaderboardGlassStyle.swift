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
// Ladder avatars only — no bee pfp here. #1 gold, #2 silver, #3 bronze;
// #4–100 get a stable random color vortex per `entry.id`. Real bee lives on
// `LeaderboardDetailView` after tap.

enum LeaderboardAvatarPalette {
    static func fill(for entry: LeaderboardEntry) -> AnyShapeStyle {
        switch entry.rank {
        case 1:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color(hex: "FFE566"),
                        Color(hex: "F0C030"),
                        Color(hex: "D4A01C"),
                        Color(hex: "A87408")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case 2:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color(hex: "FAFAFC"),
                        Color(hex: "E8EAED"),
                        Color(hex: "C4C9CF"),
                        Color(hex: "8A9096")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case 3:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color(hex: "E8A86B"),
                        Color(hex: "CD7F32"),
                        Color(hex: "B87333"),
                        Color(hex: "8B5A2B")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        default:
            return AnyShapeStyle(vortexGradient(for: entry.id))
        }
    }

    /// Multi-color swirl for ranks 4–100 (stable per user id).
    private static func vortexGradient(for entryId: String) -> AngularGradient {
        let sets: [[String]] = [
            ["FF2D92", "FF3B30", "34C759", "5AC8FA", "5856D6", "AF52DE"],
            ["FF6B6B", "FFE66D", "4ECDC4", "45B7D1", "96CEB4", "FF9FF3"],
            ["F368E0", "FF6B35", "F7C948", "00D2FF", "3A86FF", "8338EC"],
            ["EF476F", "FFD166", "06D6A0", "118AB2", "073B4C", "9B5DE5"],
            ["FB5607", "FFBE0B", "8338EC", "3A86FF", "FF006E", "06FFA5"],
            ["E63946", "F4A261", "2A9D8F", "264653", "E9C46A", "8E44AD"],
            ["FF0A54", "FF477E", "FF7096", "FF85A1", "FBB1BD", "F9DEC9"],
            ["7209B7", "3A0CA3", "4361EE", "4CC9F0", "F72585", "B5179E"],
            ["06FFA5", "00D4FF", "7B2FF7", "F107A3", "FFEE32", "FF3CAC"],
            ["00F5D4", "00BBF9", "9B5DE5", "F15BB5", "FEE440", "00F5D4"],
        ]
        let index = stableIndex(entryId, count: sets.count)
        let hexes = sets[index]
        let colors = hexes.map { Color(hex: $0) } + [Color(hex: hexes[0])]
        let rotation = Double(stableIndex(entryId + ":rot", count: 8)) * 45
        return AngularGradient(
            gradient: Gradient(colors: colors),
            center: .center,
            startAngle: .degrees(rotation),
            endAngle: .degrees(rotation + 360)
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
            .fill(LeaderboardAvatarPalette.fill(for: entry))
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .strokeBorder(Color.white.opacity(entry.rank <= 3 ? 0.35 : 0.22), lineWidth: max(1, size * 0.04))
            )
    }
}
