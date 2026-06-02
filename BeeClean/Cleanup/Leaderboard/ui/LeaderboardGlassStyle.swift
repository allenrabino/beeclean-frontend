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
// 3D glossy spheres for the ladder — #1 gold, #2 silver, #3 bronze,
// #4–100 iridescent vortex. Real bee on `LeaderboardDetailView` after tap.

enum LeaderboardAvatarPalette {
    static let lightCenter = UnitPoint(x: 0.34, y: 0.28)

    enum SphereKind {
        case gold
        case silver
        case bronze
        case vortex(AngularGradient)
    }

    static func sphereKind(for entry: LeaderboardEntry) -> SphereKind {
        switch entry.rank {
        case 1: return .gold
        case 2: return .silver
        case 3: return .bronze
        default: return .vortex(vortexGradient(for: entry.id))
        }
    }

    static func metallicRadial(kind: SphereKind, size: CGFloat) -> RadialGradient {
        let colors: [Color]
        switch kind {
        case .gold:
            colors = [
                Color(hex: "FFFDE7"),
                Color(hex: "FFEF8A"),
                Color(hex: "FFE566"),
                Color(hex: "F5C842"),
                Color(hex: "D4A82A")
            ]
        case .silver:
            colors = [
                Color(hex: "FFFFFF"),
                Color(hex: "FAFBFC"),
                Color(hex: "E8ECF2"),
                Color(hex: "CDD3DC"),
                Color(hex: "A8B0BC")
            ]
        case .bronze:
            colors = [
                Color(hex: "FFF0D6"),
                Color(hex: "FFC98E"),
                Color(hex: "F0A05C"),
                Color(hex: "D4823E"),
                Color(hex: "B86A2E")
            ]
        case .vortex:
            colors = [
                Color(hex: "5C5C70"),
                Color(hex: "454556"),
                Color(hex: "32323F")
            ]
        }
        return RadialGradient(
            colors: colors,
            center: lightCenter,
            startRadius: size * 0.02,
            endRadius: size * 0.58
        )
    }

    /// Multi-color swirl for ranks 4–100 (stable per user id).
    static func vortexGradient(for entryId: String) -> AngularGradient {
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

    private var kind: LeaderboardAvatarPalette.SphereKind {
        LeaderboardAvatarPalette.sphereKind(for: entry)
    }

    var body: some View {
        ZStack {
            sphereBody
            sphere3DLighting
            podiumEmblem
            sphereGloss
            sphereRim
        }
        .frame(width: size, height: size)
        .shadow(color: shadowColor.opacity(0.45), radius: size * 0.14, x: 0, y: size * 0.1)
        .shadow(color: Color.black.opacity(0.12), radius: size * 0.06, x: 0, y: size * 0.04)
    }

    // MARK: Body

    @ViewBuilder
    private var sphereBody: some View {
        switch kind {
        case .gold, .silver, .bronze:
            Circle()
                .fill(LeaderboardAvatarPalette.metallicRadial(kind: kind, size: size))
        case .vortex(let swirl):
            ZStack {
                Circle()
                    .fill(LeaderboardAvatarPalette.metallicRadial(kind: kind, size: size))
                Circle()
                    .fill(swirl)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.22),
                                Color.clear,
                                Color.black.opacity(0.18)
                            ],
                            center: LeaderboardAvatarPalette.lightCenter,
                            startRadius: 0,
                            endRadius: size * 0.52
                        )
                    )
                    .blendMode(.overlay)
            }
        }
    }

    // MARK: 3D Lighting

    private var sphere3DLighting: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.42), Color.clear],
                        center: UnitPoint(x: 0.32, y: 0.22),
                        startRadius: 0,
                        endRadius: size * 0.38
                    )
                )
                .blendMode(.plusLighter)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.clear, Color.black.opacity(0.38)],
                        center: UnitPoint(x: 0.58, y: 0.88),
                        startRadius: size * 0.08,
                        endRadius: size * 0.52
                    )
                )
                .blendMode(.multiply)

            Circle()
                .strokeBorder(
                    AngularGradient(
                        colors: [
                            Color.white.opacity(0.5),
                            Color.clear,
                            Color.black.opacity(0.28),
                            Color.clear,
                            Color.white.opacity(0.25)
                        ],
                        center: .center
                    ),
                    lineWidth: max(1, size * 0.035)
                )
                .blur(radius: 0.5)
                .padding(size * 0.04)
        }
        .clipShape(Circle())
    }

    // MARK: Podium Emblem (#1 crown, #2–#3 medals)

    @ViewBuilder
    private var podiumEmblem: some View {
        switch kind {
        case .gold:
            Image(systemName: "crown.fill")
                .font(.system(size: size * 0.36, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(hex: "FFFDE7"),
                            Color(hex: "FFE566"),
                            Color(hex: "E6B422")
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color(hex: "A87408").opacity(0.55), radius: 1, y: 1.5)
                .offset(y: size * 0.02)
        case .silver:
            medalEmblem(
                rank: 2,
                gradient: LinearGradient(
                    colors: [
                        Color(hex: "FFFFFF"),
                        Color(hex: "E8ECF2"),
                        Color(hex: "B0B8C4")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                shadow: Color(hex: "8A9096")
            )
        case .bronze:
            medalEmblem(
                rank: 3,
                gradient: LinearGradient(
                    colors: [
                        Color(hex: "FFE8C8"),
                        Color(hex: "F0A05C"),
                        Color(hex: "C4722A")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                shadow: Color(hex: "8B5A2B")
            )
        case .vortex:
            EmptyView()
        }
    }

    private func medalEmblem(rank: Int, gradient: LinearGradient, shadow: Color) -> some View {
        ZStack {
            Image(systemName: "medal.fill")
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(gradient)
                .shadow(color: shadow.opacity(0.5), radius: 1, y: 1.5)

            Text("\(rank)")
                .font(.system(size: size * 0.17, weight: .heavy, design: .rounded))
                .foregroundColor(rank == 2 ? Color(hex: "4B5563") : Color(hex: "5C3D1E"))
                .offset(y: size * 0.05)
        }
        .offset(y: size * 0.02)
    }

    // MARK: Gloss

    private var sphereGloss: some View {
        Ellipse()
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.78),
                        Color.white.opacity(0.22),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: size * 0.58, height: size * 0.34)
            .offset(y: -size * 0.2)
            .blur(radius: size * 0.025)
            .opacity(isPodiumSphere ? 0.5 : 1)
            .allowsHitTesting(false)
    }

    private var isPodiumSphere: Bool {
        switch kind {
        case .gold, .silver, .bronze: return true
        case .vortex: return false
        }
    }

    // MARK: Rim

    private var sphereRim: some View {
        Circle()
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.75),
                        Color.white.opacity(0.2),
                        Color.black.opacity(0.22)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: max(1.2, size * 0.045)
            )
    }

    private var shadowColor: Color {
        switch kind {
        case .gold: return Color(hex: "F0C030")
        case .silver: return Color(hex: "B8BFC8")
        case .bronze: return Color(hex: "D4823E")
        case .vortex: return Color(hex: "6B6BE8")
        }
    }
}
