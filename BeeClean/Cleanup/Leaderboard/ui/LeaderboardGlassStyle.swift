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
                Color(hex: "F5F0FF"),
                Color(hex: "EDE9FE"),
                Color(hex: "DDD6FE")
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
            (["EDE9FE", "C4B5FD", "A78BFA"], ["8B5CF6", "22D3EE", "F472B6", "FDE047", "6366F1"], ("A855F7", "22D3EE"), "7C3AED"),
            (["FFE4E6", "FDA4AF", "FB7185"], ["FF4D6D", "FF6B9D", "FB923C", "FACC15", "F472B6"], ("FB7185", "FDE047"), "E11D48"),
            (["CFFAFE", "67E8F9", "38BDF8"], ["06B6D4", "3B82F6", "A78BFA", "34D399", "22D3EE"], ("22D3EE", "818CF8"), "0284C7"),
            (["E0E7FF", "A5B4FC", "818CF8"], ["6366F1", "EC4899", "F0ABFC", "2DD4BF", "F59E0B"], ("818CF8", "F472B6"), "4F46E5"),
            (["D1FAE5", "6EE7B7", "34D399"], ["10B981", "22D3EE", "A3E635", "4ADE80", "2DD4BF"], ("4ADE80", "22D3EE"), "059669"),
            (["FFEDD5", "FDBA74", "FB923C"], ["F97316", "FACC15", "F472B6", "FB7185", "A78BFA"], ("FB923C", "F472B6"), "EA580C"),
            (["F3E8FF", "D8B4FE", "C084FC"], ["A855F7", "EC4899", "F472B6", "38BDF8", "FDE047"], ("C084FC", "38BDF8"), "9333EA"),
            (["E0F2FE", "93C5FD", "60A5FA"], ["3B82F6", "818CF8", "F0ABFC", "22D3EE", "A3E635"], ("60A5FA", "F0ABFC"), "2563EB"),
            (["FCE7F3", "F9A8D4", "F472B6"], ["EC4899", "FB7185", "F59E0B", "38BDF8", "A78BFA"], ("F472B6", "38BDF8"), "DB2777"),
            (["CCFBF1", "5EEAD4", "2DD4BF"], ["14B8A6", "06B6D4", "6366F1", "F472B6", "FACC15"], ("2DD4BF", "818CF8"), "0D9488"),
        ]

        let index = stableIndex(entryId, count: schemes.count)
        let scheme = schemes[index]
        let foundation = scheme.foundation.map { Color(hex: $0) }
        let blobColors = scheme.blobs.map { Color(hex: $0) }

        let blobs = (0..<5).map { i in
            let angleDeg = Double(stableIndex(entryId + ":θ\(i)", count: 360))
            let dist = 0.1 + Double(stableIndex(entryId + ":d\(i)", count: 18)) / 100.0
            let radians = angleDeg * .pi / 180
            let scale = 0.68 + CGFloat(stableIndex(entryId + ":s\(i)", count: 24)) / 100.0
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
    @ObservedObject private var bitePalVM = BitePalViewModel.shared

    let entry: LeaderboardEntry
    var size: CGFloat

    private var kind: LeaderboardAvatarPalette.SphereKind {
        LeaderboardAvatarPalette.sphereKind(for: entry)
    }

    private var selfEquippedIds: [String] {
        let live = bitePalVM.equippedIds
        return live.isEmpty ? entry.equippedAccessoryIds : live
    }

    var body: some View {
        if entry.isSelf {
            selfBeeAvatar
        } else {
            rankedSphereAvatar
        }
    }

    // MARK: Self — real bee pfp

    private var selfBeeAvatar: some View {
        BeeAvatarView(equippedAssetIds: selfEquippedIds, size: size * 0.9)
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "FFF8E1"), Color(hex: "FFE566")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .clipShape(Circle())
            .overlay(
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color(hex: "FFE566"),
                                Color(hex: "D4A01C"),
                                Color(hex: "A87408")
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: max(1.5, size * 0.045)
                    )
            )
            .shadow(color: Color(hex: "D4A01C").opacity(0.28), radius: size * 0.1, x: 0, y: size * 0.06)
    }

    // MARK: Everyone else — colorful sphere

    private var rankedSphereAvatar: some View {
        ZStack {
            sphereBody
            sphere3DLighting
            podiumEmblem
            sphereGloss
            sphereRim
        }
        .frame(width: size, height: size)
        .shadow(color: shadowColor.opacity(isMistSphere ? 0.55 : 0.45), radius: size * 0.14, x: 0, y: size * 0.1)
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
            .opacity(isPodiumSphere ? 0.5 : 0.38)
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

    private var auroraColors: [Color] {
        palette.blobs.map(\.color) + [palette.driftTop, palette.driftBottom]
    }

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
                    AngularGradient(
                        colors: auroraColors + [auroraColors.first ?? palette.driftTop],
                        center: .center
                    )
                )
                .opacity(0.72)
                .blur(radius: size * 0.11)
                .blendMode(.screen)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            palette.driftTop.opacity(0.72),
                            palette.driftBottom.opacity(0.65)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blendMode(.overlay)

            ForEach(Array(palette.blobs.enumerated()), id: \.offset) { _, blob in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                blob.color,
                                blob.color.opacity(0.82),
                                blob.color.opacity(0.38),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: size * blob.scale * 0.52
                        )
                    )
                    .frame(width: size * blob.scale, height: size * blob.scale)
                    .position(x: size * blob.center.x, y: size * blob.center.y)
                    .blur(radius: size * 0.065)
                    .blendMode(.normal)
            }

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.28),
                            Color.clear
                        ],
                        center: UnitPoint(x: 0.36, y: 0.26),
                        startRadius: 0,
                        endRadius: size * 0.38
                    )
                )
                .blendMode(.softLight)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.clear,
                            palette.shadowTint.opacity(0.28)
                        ],
                        center: UnitPoint(x: 0.55, y: 0.82),
                        startRadius: size * 0.05,
                        endRadius: size * 0.5
                    )
                )
                .blendMode(.multiply)
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .saturation(1.22)
        .contrast(1.06)
    }
}
