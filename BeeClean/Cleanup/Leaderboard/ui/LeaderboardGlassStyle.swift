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
// #4–100 soft cloud-mist gradients. Real bee on `LeaderboardDetailView` after tap.

enum LeaderboardAvatarPalette {
    static let lightCenter = UnitPoint(x: 0.34, y: 0.28)

    enum SphereKind {
        case gold
        case silver
        case bronze
        case mist(MistPalette)
    }

    struct MistBlob {
        let color: Color
        let center: UnitPoint
        let scale: CGFloat
    }

    struct MistPalette {
        let foundation: [Color]
        let blobs: [MistBlob]
        let driftTop: Color
        let driftBottom: Color
        let shadowTint: Color
    }

    static func sphereKind(for entry: LeaderboardEntry) -> SphereKind {
        switch entry.rank {
        case 1: return .gold
        case 2: return .silver
        case 3: return .bronze
        default: return .mist(mistPalette(for: entry.id))
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
        case .mist:
            colors = [
                Color(hex: "FAFCFF"),
                Color(hex: "F0F4FF"),
                Color(hex: "E8EEF8")
            ]
        }
        return RadialGradient(
            colors: colors,
            center: lightCenter,
            startRadius: size * 0.02,
            endRadius: size * 0.58
        )
    }

    /// Soft cloud / smoke palette for ranks 4–100 (stable per user id).
    static func mistPalette(for entryId: String) -> MistPalette {
        let schemes: [(foundation: [String], blobs: [String], drift: (String, String), shadow: String)] = [
            (["FAF8FF", "F3EEFF", "E9E0FF"], ["DDD6FE", "C4B5FD", "E0E7FF", "F5F3FF"], ("EDE9FE", "E0F2FE"), "A78BFA"),
            (["FFF8FB", "FFF1F5", "FFE4EC"], ["FECDD3", "FBCFE8", "FDA4AF", "FFE4E6"], ("FCE7F3", "FFEDD5"), "FB7185"),
            (["F8FDFF", "ECFEFF", "E0F2FE"], ["BAE6FD", "A5F3FC", "7DD3FC", "E0F2FE"], ("CFFAFE", "E0E7FF"), "38BDF8"),
            (["FAFAFF", "EEF2FF", "E8EDFF"], ["C7D2FE", "A5B4FC", "E9D5FF", "F0ABFC"], ("E0E7FF", "FAE8FF"), "818CF8"),
            (["F7FDF9", "F0FDF4", "ECFDF5"], ["BBF7D0", "A7F3D0", "D9F99D", "E0F2FE"], ("DCFCE7", "E0F2FE"), "4ADE80"),
            (["FFFBF5", "FFF7ED", "FFEDD5"], ["FED7AA", "FBCFE8", "FDE68A", "E9D5FF"], ("FFEDD5", "FCE7F3"), "F59E0B"),
            (["FAFAFF", "F5F3FF", "EDE9FE"], ["E9D5FF", "DDD6FE", "C4B5FD", "F0ABFC"], ("F5F3FF", "E0E7FF"), "C084FC"),
            (["F8FAFC", "F1F5F9", "E2E8F0"], ["E2E8F0", "CBD5E1", "E9D5FF", "BAE6FD"], ("F1F5F9", "E0E7FF"), "94A3B8"),
            (["FFF9FB", "FFF1F2", "FFEDD5"], ["FECACA", "FBCFE8", "FDE68A", "BAE6FD"], ("FFE4E6", "E0F2FE"), "F472B6"),
            (["F5FAFF", "EFF6FF", "E0F2FE"], ["BFDBFE", "BAE6FD", "E9D5FF", "FCE7F3"], ("DBEAFE", "F5F3FF"), "60A5FA"),
        ]

        let index = stableIndex(entryId, count: schemes.count)
        let scheme = schemes[index]
        let foundation = scheme.foundation.map { Color(hex: $0) }
        let blobColors = scheme.blobs.map { Color(hex: $0) }

        let blobs = (0..<4).map { i in
            let angleDeg = Double(stableIndex(entryId + ":θ\(i)", count: 360))
            let dist = 0.1 + Double(stableIndex(entryId + ":d\(i)", count: 18)) / 100.0
            let radians = angleDeg * .pi / 180
            let scale = 0.62 + CGFloat(stableIndex(entryId + ":s\(i)", count: 22)) / 100.0
            return MistBlob(
                color: blobColors[i % blobColors.count],
                center: UnitPoint(
                    x: 0.5 + cos(radians) * dist,
                    y: 0.5 + sin(radians) * dist
                ),
                scale: scale
            )
        }

        return MistPalette(
            foundation: foundation,
            blobs: blobs,
            driftTop: Color(hex: scheme.drift.0),
            driftBottom: Color(hex: scheme.drift.1),
            shadowTint: Color(hex: scheme.shadow)
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
        case .mist(let palette):
            LeaderboardMistSphere(palette: palette, size: size)
        }
    }

    // MARK: 3D Lighting

    private var sphere3DLighting: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(isMistSphere ? 0.32 : 0.42), Color.clear],
                        center: UnitPoint(x: 0.32, y: 0.22),
                        startRadius: 0,
                        endRadius: size * 0.38
                    )
                )
                .blendMode(.plusLighter)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.clear, Color.black.opacity(isMistSphere ? 0.18 : 0.38)],
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
                            Color.black.opacity(isMistSphere ? 0.12 : 0.28),
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
        case .mist:
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
            .opacity(isPodiumSphere ? 0.5 : 0.65)
            .allowsHitTesting(false)
    }

    private var isPodiumSphere: Bool {
        switch kind {
        case .gold, .silver, .bronze: return true
        case .mist: return false
        }
    }

    private var isMistSphere: Bool {
        if case .mist = kind { return true }
        return false
    }

    // MARK: Rim

    private var sphereRim: some View {
        Circle()
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.75),
                        Color.white.opacity(0.2),
                        Color.black.opacity(isMistSphere ? 0.08 : 0.22)
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
        case .mist(let palette): return palette.shadowTint
        }
    }
}

// MARK: - Cloud Mist Sphere (ranks 4–100)

private struct LeaderboardMistSphere: View {
    let palette: LeaderboardAvatarPalette.MistPalette
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: palette.foundation + [palette.foundation.last ?? .white],
                        center: LeaderboardAvatarPalette.lightCenter,
                        startRadius: 0,
                        endRadius: size * 0.58
                    )
                )

            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            palette.driftTop.opacity(0.5),
                            Color.white.opacity(0.12),
                            palette.driftBottom.opacity(0.48)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blendMode(.softLight)

            ForEach(Array(palette.blobs.enumerated()), id: \.offset) { _, blob in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                blob.color.opacity(0.95),
                                blob.color.opacity(0.55),
                                blob.color.opacity(0.12),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: size * blob.scale * 0.5
                        )
                    )
                    .frame(width: size * blob.scale, height: size * blob.scale)
                    .position(x: size * blob.center.x, y: size * blob.center.y)
                    .blur(radius: size * 0.09)
                    .blendMode(.plusLighter)
            }

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.5),
                            Color.white.opacity(0.08),
                            Color.clear
                        ],
                        center: UnitPoint(x: 0.36, y: 0.26),
                        startRadius: 0,
                        endRadius: size * 0.42
                    )
                )
                .blendMode(.screen)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.clear,
                            palette.driftBottom.opacity(0.22),
                            palette.shadowTint.opacity(0.14)
                        ],
                        center: UnitPoint(x: 0.55, y: 0.82),
                        startRadius: size * 0.05,
                        endRadius: size * 0.52
                    )
                )
                .blendMode(.multiply)
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}
