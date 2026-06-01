import SwiftUI

// MARK: - Today's Cleanup Card
/// Gamified cleanup mission panel replacing the old HiveScoreCard.
/// Hierarchy: big storage value → Clean Bar progression → status text → tasks → CTA.
struct TodaysCleanupCard: View {
    let plan: TodayCleanupPlan
    let stage: BeeStage
    let potentialCoins: Int
    /// Persisted active task (Shuffling System). Drives the numbered label.
    var activeTask: ActiveCleanupTask? = nil
    /// Up to 2 most-recent completed tasks (newest first) for the greyed stack.
    var recentCompleted: [CompletedCleanupTask] = []
    let onStartCleanup: () -> Void
    var onViewAll: () -> Void = {}

    @ObservedObject private var statsManager = HiveStatsManager.shared
    @ObservedObject private var progress = ProgressManager.shared
    @ObservedObject private var libraryBytes = PhotoLibraryBytesService.shared
    @State private var shimmerOffset: CGFloat = -1
    @State private var appeared = false
    @State private var topDestination: CardTopDestination?

    enum CardTopDestination: Hashable {
        case shop, leaderboard, coins
    }

    /// The "Space to Clean" headline. Defaults to our scan-derived
    /// clutter bytes, but we ceiling on Apple Photos' library total —
    /// because the user has called us out for showing 45.8 GB when
    /// Photos shows 50.67 GB. Until our scan covers every asset class
    /// Photos counts (Live Photos, RAW, edited originals), surfacing
    /// the Apple-equivalent total as the headline keeps us honest.
    /// When our scan eventually equals or exceeds Photos' number,
    /// `formattedHeadlineBytes` becomes a pure pass-through.
    private var formattedHeadlineBytes: String {
        let scan = plan.totalRecoverableBytes
        let library = libraryBytes.totalLibraryBytes
        guard library > scan else { return plan.formattedTotalBytes }
        return Self.formatBytes(library)
    }

    static func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    private var isEmpty: Bool { plan.tasks.isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            // 1. Big headline value (primary)
            headlineSection
                .padding(.bottom, 14)

            // 2. Clean Bar progression (prominent, emotionally rewarding)
            cleanBarSection
                .padding(.bottom, isEmpty ? 0 : 16)

            // 4. Today's tasks
            if !isEmpty {
                taskListSection
                    .padding(.bottom, 18)

                // 5. CTA button
                ctaButton
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 20)
        .padding(.bottom, isEmpty ? 20 : 18)
        .frame(maxWidth: .infinity)
        .background(cardSurface)
        .shadow(
            color: stage.isUnclean
                ? Color.destructive.opacity(0.15)
                : Color(hex: "C4850A").opacity(0.10),
            radius: 18, x: 0, y: 8
        )
        .onAppear {
            withAnimation(
                .linear(duration: 2.0)
                .delay(0.8)
                .repeatForever(autoreverses: false)
            ) {
                shimmerOffset = 2
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
        }
        .animation(.easeInOut(duration: 0.45), value: stage)
    }

    // MARK: - Headline Section

    private var headlineSection: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(BCLoc.totalSpaceToClean.tr)
                    .font(.custom("Poppins-Bold", size: 11.5))
                    .tracking(0.6)
                    .textCase(.uppercase)
                    .foregroundColor(Color(hex: "1C1917"))
                    .lineLimit(1)

                Text(formattedHeadlineBytes)
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundColor(Color.foreground)
                    .tracking(-1.0)
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Spacer(minLength: 0)

            cardTopActions
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 8)
        // Shop opens as a bottom sheet (BitePal-style: it overtakes the
        // lower half of the dashboard and the grip-handle drag drops
        // back to the homepage). Leaderboard + Coins still push as
        // regular destinations.
        .sheet(isPresented: Binding(
            get: { topDestination == .shop },
            set: { if !$0 { topDestination = nil } }
        )) {
            // Sheet top edge lands exactly where the Total Space to
            // Clean card starts. The bee hero takes ~50% of screen
            // height, so a 0.50 detent puts the sheet's top edge
            // right at the card's top edge — the store visually
            // "replaces" the lower stack (TSC + Quick Access + Source
            // row) without covering the bee. Drag up to expand to
            // full screen, drag down to dismiss.
            // Sheet top edge sits AT the Total Space to Clean card's
            // top edge — covers the card + Quick Access row + Source
            // row in one sweep, matching BitePal's "store takes over
            // the lower half of the home" pattern.
            BitePalView()
                .presentationDetents([.fraction(0.65), .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
        }
        .navigationDestination(item: Binding(
            get: { topDestination != .shop ? topDestination : nil },
            set: { if $0 == nil && topDestination != .shop { topDestination = nil } }
        )) { dest in
            switch dest {
            case .shop:        EmptyView()
            case .leaderboard: LeaderboardView().hidesBottomNavBar()
            case .coins:       CoinsView().hidesBottomNavBar()
            }
        }
    }

    // MARK: - Card Top Actions
    //
    // Sleek icon strip in the top-right of the Total Space to Clean card.
    // Sits on the white card surface so the dark monochrome glyphs read
    // clearly (the screen-header version was getting drowned by the
    // night sky). Anchored to the card means the icons scroll WITH the
    // card content — they're a card affordance, not screen chrome.
    private var cardTopActions: some View {
        // Wider spacing so the three stickers breathe instead of crowding
        // the top-right corner.
        HStack(spacing: 16) {
            // Cartoon shop — sized to match the coin glyph so the three top
            // icons read at one visual weight.
            Button { topDestination = .shop } label: {
                CartoonShop().frame(width: 26, height: 26)
            }
            .buttonStyle(.plain)

            // Cartoon trophy — matched to the coin.
            Button { topDestination = .leaderboard } label: {
                CartoonTrophy().frame(width: 26, height: 26)
            }
            .buttonStyle(.plain)

            // BiteCoins — matches the amber centsign coin used in the
            // rewards rows + Coins screen so the currency reads identically
            // everywhere.
            Button { topDestination = .coins } label: {
                HStack(spacing: 4) {
                    CoinBadge(size: 22)
                    Text("\(statsManager.coinsBalance)")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundColor(Color(hex: "C4850A"))
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Cartoon Icon Kit
    //
    // Hand-built vector cartoon icons for the shop / trophy / coin strip —
    // actual illustrated objects (striped shop, handled trophy, ridged coin)
    // rather than recoloured SF glyphs. Dark "ink" outlines + white shine
    // give the soft BitePal sticker feel. No asset files / pbxproj churn.
    private enum BiteCartoon {
        static let ink = Color(hex: "4A2E08")
        static let cream = Color(hex: "FFF4DC")
        static let goldTop = Color(hex: "FFE490")
        static let goldDeep = Color(hex: "EC9A1E")
        static let coralTop = Color(hex: "FF8A6B")
        static let coralDeep = Color(hex: "F0533C")
        static var gold: LinearGradient {
            LinearGradient(colors: [goldTop, goldDeep], startPoint: .top, endPoint: .bottom)
        }
        static var coral: LinearGradient {
            LinearGradient(colors: [coralTop, coralDeep], startPoint: .top, endPoint: .bottom)
        }
    }

    /// A cartoon shop: striped scalloped awning over a cream storefront with
    /// a door + round window.
    private struct CartoonShop: View {
        var body: some View {
            GeometryReader { geo in
                let s = min(geo.size.width, geo.size.height)
                ZStack {
                    // Storefront body.
                    RoundedRectangle(cornerRadius: s * 0.08)
                        .fill(BiteCartoon.cream)
                        .overlay(
                            RoundedRectangle(cornerRadius: s * 0.08)
                                .strokeBorder(BiteCartoon.ink, lineWidth: s * 0.055)
                        )
                        .frame(width: s * 0.7, height: s * 0.46)
                        .position(x: s * 0.5, y: s * 0.64)
                    // Door.
                    RoundedRectangle(cornerRadius: s * 0.03)
                        .fill(BiteCartoon.coral)
                        .overlay(
                            RoundedRectangle(cornerRadius: s * 0.03)
                                .strokeBorder(BiteCartoon.ink, lineWidth: s * 0.04)
                        )
                        .frame(width: s * 0.2, height: s * 0.26)
                        .position(x: s * 0.42, y: s * 0.74)
                    // Round window.
                    Circle()
                        .fill(BiteCartoon.goldTop)
                        .overlay(Circle().strokeBorder(BiteCartoon.ink, lineWidth: s * 0.04))
                        .frame(width: s * 0.13, height: s * 0.13)
                        .position(x: s * 0.63, y: s * 0.66)
                    // Striped scalloped awning.
                    StripedAwning()
                        .frame(width: s * 0.84, height: s * 0.22)
                        .position(x: s * 0.5, y: s * 0.32)
                }
                .frame(width: s, height: s)
            }
        }
    }

    private struct StripedAwning: View {
        var body: some View {
            GeometryReader { geo in
                let w = geo.size.width, h = geo.size.height
                let shape = AwningShape()
                ZStack {
                    HStack(spacing: 0) {
                        ForEach(0..<6, id: \.self) { i in
                            Rectangle().fill(i % 2 == 0 ? BiteCartoon.coralDeep : BiteCartoon.cream)
                        }
                    }
                    .clipShape(shape)
                    shape.stroke(BiteCartoon.ink,
                                 style: StrokeStyle(lineWidth: min(w, h) * 0.16, lineJoin: .round))
                }
            }
        }
    }

    private struct AwningShape: Shape {
        func path(in r: CGRect) -> Path {
            var p = Path()
            let w = r.width, h = r.height
            p.move(to: CGPoint(x: r.minX, y: r.minY))
            p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
            p.addLine(to: CGPoint(x: r.maxX, y: r.minY + h * 0.5))
            let scallops = 5
            let sw = w / CGFloat(scallops)
            var x = r.maxX
            for _ in 0..<scallops {
                let nx = x - sw
                p.addQuadCurve(to: CGPoint(x: nx, y: r.minY + h * 0.5),
                               control: CGPoint(x: x - sw / 2, y: r.minY + h * 1.02))
                x = nx
            }
            p.closeSubpath()
            return p
        }
    }

    /// A cartoon trophy: gold cup with side handles, a star, stem + base.
    private struct CartoonTrophy: View {
        var body: some View {
            GeometryReader { geo in
                let s = min(geo.size.width, geo.size.height)
                ZStack {
                    // Handles behind the cup — ink outline then gold core.
                    TrophyHandles().stroke(BiteCartoon.ink,
                        style: StrokeStyle(lineWidth: s * 0.16, lineCap: .round))
                    TrophyHandles().stroke(BiteCartoon.gold,
                        style: StrokeStyle(lineWidth: s * 0.08, lineCap: .round))
                    // Cup + stem + base.
                    TrophyCup().fill(BiteCartoon.gold)
                    TrophyCup().stroke(BiteCartoon.ink,
                        style: StrokeStyle(lineWidth: s * 0.055, lineJoin: .round))
                    // Star on the bowl.
                    Image(systemName: "star.fill")
                        .font(.system(size: s * 0.2, weight: .black))
                        .foregroundColor(.white.opacity(0.92))
                        .position(x: s * 0.5, y: s * 0.3)
                    // Shine streak.
                    Capsule().fill(.white.opacity(0.55))
                        .frame(width: s * 0.05, height: s * 0.13)
                        .rotationEffect(.degrees(14))
                        .position(x: s * 0.37, y: s * 0.26)
                }
                .frame(width: s, height: s)
            }
        }
    }

    private struct TrophyCup: Shape {
        func path(in r: CGRect) -> Path {
            let w = r.width, h = r.height
            func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                CGPoint(x: r.minX + x * w, y: r.minY + y * h)
            }
            func box(_ x: CGFloat, _ y: CGFloat, _ bw: CGFloat, _ bh: CGFloat) -> CGRect {
                CGRect(x: r.minX + x * w, y: r.minY + y * h, width: bw * w, height: bh * h)
            }
            var p = Path()
            // Bowl
            p.move(to: P(0.24, 0.12))
            p.addLine(to: P(0.76, 0.12))
            p.addCurve(to: P(0.50, 0.58), control1: P(0.76, 0.46), control2: P(0.63, 0.58))
            p.addCurve(to: P(0.24, 0.12), control1: P(0.37, 0.58), control2: P(0.24, 0.46))
            p.closeSubpath()
            // Stem
            p.addRoundedRect(in: box(0.45, 0.56, 0.10, 0.15),
                             cornerSize: CGSize(width: w * 0.02, height: w * 0.02))
            // Base bar
            p.addRoundedRect(in: box(0.36, 0.69, 0.28, 0.07),
                             cornerSize: CGSize(width: w * 0.02, height: w * 0.02))
            // Plinth
            p.addRoundedRect(in: box(0.30, 0.78, 0.40, 0.09),
                             cornerSize: CGSize(width: w * 0.03, height: w * 0.03))
            return p
        }
    }

    private struct TrophyHandles: Shape {
        func path(in r: CGRect) -> Path {
            let w = r.width, h = r.height
            func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                CGPoint(x: r.minX + x * w, y: r.minY + y * h)
            }
            var p = Path()
            // Left handle
            p.move(to: P(0.25, 0.16))
            p.addCurve(to: P(0.30, 0.42), control1: P(0.05, 0.16), control2: P(0.07, 0.44))
            // Right handle
            p.move(to: P(0.75, 0.16))
            p.addCurve(to: P(0.70, 0.42), control1: P(0.95, 0.16), control2: P(0.93, 0.44))
            return p
        }
    }

    // MARK: - Clean Bar Section

    private var cleanBarSection: some View {
        CleanBarView()
    }

    // MARK: - Status Subtitle

    private var statusSubtitle: some View {
        Text(plan.subtitle)
            .font(.custom("Poppins-Medium", size: 12.5))
            .foregroundColor(Color.mutedForeground.opacity(0.65))
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 4)
    }

    // MARK: - Task List Section

    /// Capped task stack: up to 2 greyed-out recently-completed tasks above the
    /// full-color active task (max 3 rows total). Plus a "View All" entry to the
    /// full history. Labels are the numbered "Task #X" progression.
    private var taskListSection: some View {
        VStack(spacing: 8) {
            // Header + View All
            HStack {
                Text("Cleanup Tasks")
                    .font(.custom("Poppins-Bold", size: 12.5))
                    .foregroundColor(Color.foreground.opacity(0.72))
                    .tracking(0.4)
                Spacer()
                Button(action: { HapticManager.shared.impact(.light); onViewAll() }) {
                    HStack(spacing: 2) {
                        Text("View All")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundColor(Color(hex: "C4850A"))
                }
                .buttonStyle(.plain)
            }

            VStack(spacing: 0) {
                // Greyed completed cards — oldest on top, newest just above active.
                let completed = Array(recentCompleted.prefix(2).reversed())
                ForEach(Array(completed.enumerated()), id: \.element.taskNumber) { _, t in
                    stackRow(
                        title: t.displayTitle,
                        bytesText: Self.mbText(t.mbReviewed),
                        coins: t.coinsEarned,
                        category: Self.category(from: t.category),
                        greyed: true
                    )
                    stackDivider
                }

                // Active task — full color, the one the CTA launches.
                stackRow(
                    title: activeTask?.displayTitle ?? BCLoc.quickCleanup.tr,
                    bytesText: plan.formattedRoundBytes,
                    coins: potentialCoins,
                    category: Self.category(from: activeTask?.category),
                    greyed: false
                )
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                    .fill(Color(hex: "F8F6F2"))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                            .stroke(Color.black.opacity(0.04), lineWidth: 0.5)
                    )
            )
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 4)
    }

    private var stackDivider: some View {
        Rectangle()
            .fill(Color.black.opacity(0.05))
            .frame(height: 0.5)
            .padding(.leading, 34)
    }

    private func stackRow(title: String, bytesText: String, coins: Int, category: CleanupTaskCategory, greyed: Bool) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(greyed ? Color(hex: "E7E1DA") : Color(hex: "FFC648"))
                    .frame(width: 24, height: 24)
                Image(systemName: greyed ? "checkmark" : "flag.fill")
                    .font(.system(size: greyed ? 11 : 12, weight: .semibold))
                    .foregroundColor(greyed ? Color.mutedForeground : .black)
            }
            .frame(width: 24, height: 24)

            Text(title)
                .font(.system(size: 13.5, weight: .medium, design: .rounded))
                .foregroundColor(Color.foreground)
                .lineLimit(1)

            Text(bytesText)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(Color.mutedForeground)

            Spacer(minLength: 4)

            if coins > 0 {
                HStack(spacing: 3) {
                    CoinBadge(size: 13)
                    Text("+\(coins)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "C4850A"))
                }
            }
        }
        .padding(.vertical, 10)
        .opacity(greyed ? 0.5 : 1.0)
    }

    static func mbText(_ mb: Double) -> String {
        CleanupRound.formatBytes(Int64(mb * 1_000_000))
    }

    static func category(from raw: String?) -> CleanupTaskCategory {
        CleanupTaskCategory(rawValue: raw ?? "") ?? .otherPhotos
    }

    // MARK: - CTA Button

    private var ctaButton: some View {
        Button(action: {
            HapticManager.shared.primaryCommit()
            onStartCleanup()
        }) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .bold))

                Text("Start Quick Cleanup")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .tracking(-0.2)
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(ctaBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 0.75)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 6)
    }

    private var ctaBackground: some View {
        Color(hex: "FFC648")
    }

    // MARK: - Card Surface

    private var cardSurface: some View {
        let shape = RoundedRectangle(cornerRadius: DesignTokens.Radius.xl, style: .continuous)
        return ZStack {
            shape.fill(Color.card)
            shape.stroke(borderGradient, lineWidth: 0.9)
        }
        .compositingGroup()
    }

    private var borderGradient: LinearGradient {
        if stage.isUnclean {
            return LinearGradient(
                colors: [
                    Color.destructive.opacity(0.30),
                    Color.destructive.opacity(0.08)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        return LinearGradient(
            colors: [
                Color.white.opacity(0.55),
                Color(hex: "CFAF5F").opacity(0.28),
                Color(hex: "7A5C2E").opacity(0.10)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Colors

    private func iconColor(for category: CleanupTaskCategory) -> Color {
        switch category {
        case .duplicatePhotos: return .categorySky
        case .similarPhotos: return .categoryViolet
        case .similarScreenshots: return .categoryTeal
        case .screenshots: return .categoryAmber
        case .blurryPhotos: return .categoryRose
        case .similarVideos: return .categoryCrimson
        case .screenRecordings: return .categoryIndigo
        case .shortRecordings: return .categoryMint
        case .longVideos: return .categoryCocoa
        case .otherPhotos: return .categorySlate
        case .promoEmails: return .categorySlate
        }
    }
}

// MARK: - Coin Badge
/// The ONE canonical BeeCoin glyph, app-wide. Matches the homepage top-bar
/// coin pill (`bitcoinsign.circle.fill` in the honey gradient) so every coin
/// across the app reads as the same logo — dashboard, cleanup card, history,
/// Coins screen, Progress, leaderboard, shop. Don't render a different coin
/// symbol anywhere; use this.
struct CoinBadge: View {
    var size: CGFloat = 16

    var body: some View {
        Image(systemName: "bitcoinsign.circle.fill")
            .font(.system(size: size, weight: .bold))
            .foregroundStyle(LinearGradient.honeyGradient)
    }
}

#Preview {
    let fullPlan = TodayCleanupPlan(
        totalRecoverableBytes: 2_400_000_000,
        roundBytes: 1_200_000_000,
        tasks: [
            CleanupTask(id: "1", icon: "doc.on.doc.fill", title: "5 duplicate screenshots", estimatedBytes: 450_000_000, category: .duplicatePhotos),
            CleanupTask(id: "2", icon: "film.fill", title: "1 large video", estimatedBytes: 380_000_000, category: .longVideos),
            CleanupTask(id: "3", icon: "camera.metering.unknown", title: "3 blurry photos", estimatedBytes: 220_000_000, category: .blurryPhotos),
            CleanupTask(id: "4", icon: "rectangle.on.rectangle", title: "4 similar screenshots", estimatedBytes: 150_000_000, category: .similarScreenshots),
        ],
        estimatedSeconds: 45,
        beeHealthScore: 58,
        subtitle: "Bee found a quick cleanup for you"
    )

    let scanningPlan = TodayCleanupPlan(
        totalRecoverableBytes: 0,
        roundBytes: 0,
        tasks: [],
        estimatedSeconds: 0,
        beeHealthScore: 12,
        subtitle: "Scanning for cleanup tasks..."
    )

    ScrollView {
        VStack(spacing: 24) {
            TodaysCleanupCard(plan: fullPlan, stage: .stage3, potentialCoins: 8) {}
            TodaysCleanupCard(plan: fullPlan, stage: .stage1, potentialCoins: 8) {}
            TodaysCleanupCard(plan: scanningPlan, stage: .stage2, potentialCoins: 0) {}
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 40)
    }
    .background(Color.background)
}
