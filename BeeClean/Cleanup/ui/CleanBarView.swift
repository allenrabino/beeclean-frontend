import SwiftUI
import Combine

// MARK: - Clean Bar View
/// The gamified Clean Bar progression: "Clean Bar · Lv X" + BiteCoins count +
/// golden capsule fill driven by `ProgressManager.shared.cleanBarPercent`.
/// Single source of truth shared by the home `TodaysCleanupCard` and the
/// Quick Cleanup checkpoint celebration card so the two never drift.
///
/// Pass `animatedBoost` > 0 (the coins a checkpoint just earned) to play a live
/// count-up: the bar fills from the current total, popping + incrementing the
/// level on each boundary it crosses, ending exactly where the real award lands.
struct CleanBarView: View {
    var animatedBoost: Int = 0

    @ObservedObject private var progress = ProgressManager.shared
    @State private var animatedScore: CGFloat = 0
    @State private var appeared = false

    // Boost-mode animation state.
    @State private var isAnimating = false
    @State private var displayedTotal: Double = 0
    @State private var target: Double = 0
    @State private var perTick: Double = 0
    @State private var animLevel = 1
    @State private var animCoins = 0
    @State private var animNeeded = 1
    @State private var animPercent: Double = 0
    @State private var levelPulse = false
    @State private var pauseTicks = 0
    @State private var pending: ProgressMath.DerivedProgress?

    private let frameTimer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    private var isBoosting: Bool { animatedBoost > 0 }

    private var showLevel: Int { isBoosting ? animLevel : progress.currentLevel }
    private var showCoins: Int { isBoosting ? animCoins : progress.currentLevelCoins }
    private var showNeeded: Int { isBoosting ? animNeeded : progress.coinsNeededForNextLevel }

    private var scoreColor: Color { Color.foreground }
    private var scoreGradient: some ShapeStyle { Color(hex: "FFC648") }

    var body: some View {
        VStack(spacing: 7) {
            // Label row
            HStack(alignment: .firstTextBaseline) {
                Text("Clean Bar · Lv \(showLevel)")
                    .font(.custom("Poppins-Bold", size: 12.5))
                    .foregroundColor(Color.foreground.opacity(0.72))
                    .tracking(0.4)
                    .scaleEffect(levelPulse ? 1.12 : 1, anchor: .leading)

                Spacer()

                Text("\(showCoins)")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundColor(scoreColor)
                +
                Text(" / \(showNeeded) BiteCoins")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.mutedForeground.opacity(0.55))
            }

            // Progress pill — taller, glowing, game-like
            GeometryReader { geo in
                let pct = isBoosting ? animPercent : Double(animatedScore)
                let fillWidth = geo.size.width * min(max(pct, 0.02), 1.0)

                ZStack(alignment: .leading) {
                    // Track — subtle warm tint
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "EDE8E2").opacity(0.7),
                                    Color(hex: "E7E1DA").opacity(0.5)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    // Fill — flat solid color matching CTA button
                    Capsule()
                        .fill(scoreGradient)
                        .frame(width: fillWidth)
                        .shadow(
                            color: Color(hex: "FFC648").opacity(levelPulse ? 0.7 : 0),
                            radius: levelPulse ? 8 : 0
                        )
                }
            }
            .frame(height: 14)
            .clipShape(Capsule())
            .scaleEffect(y: levelPulse ? 1.18 : 1, anchor: .center)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 6)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
            if isBoosting {
                startBoost()
            } else {
                withAnimation(.easeOut(duration: 1.4).delay(0.25)) {
                    animatedScore = CGFloat(progress.cleanBarPercent)
                }
            }
        }
        .onChange(of: progress.cleanBarPercent) { _, newValue in
            guard !isBoosting else { return }
            withAnimation(.easeOut(duration: 0.8)) {
                animatedScore = CGFloat(newValue)
            }
        }
        .onReceive(frameTimer) { _ in tick() }
        .onDisappear { isAnimating = false }
    }

    // MARK: - Boost animation

    private func startBoost() {
        let base = ProgressManager.shared.totalLifetimeCoins
        let d = ProgressManager.shared.derivedProgress(forTotal: base)
        displayedTotal = Double(base)
        target = Double(base + animatedBoost)
        animLevel = d.currentLevel
        animCoins = d.currentLevelCoins
        animNeeded = d.coinsNeededForNextLevel
        animPercent = d.cleanBarPercent
        let duration = min(2.0, max(0.8, Double(animatedBoost) * 0.06))
        perTick = max(0.0001, Double(animatedBoost) / (duration * 60.0))
        // Beat for the screen to settle / coins to launch toward the bar.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isAnimating = true
        }
    }

    private func tick() {
        guard isAnimating else { return }

        if pauseTicks > 0 {
            pauseTicks -= 1
            if pauseTicks == 0, let p = pending {
                // Pop finished — snap to the new level, near-empty, and resume.
                animLevel = p.currentLevel
                animCoins = p.currentLevelCoins
                animNeeded = p.coinsNeededForNextLevel
                animPercent = p.cleanBarPercent
                pending = nil
                withAnimation(.easeOut(duration: 0.18)) { levelPulse = false }
            }
            return
        }

        displayedTotal += perTick
        if displayedTotal >= target {
            displayedTotal = target
            let d = ProgressManager.shared.derivedProgress(forTotal: Int(target.rounded()))
            animLevel = d.currentLevel
            animCoins = d.currentLevelCoins
            animNeeded = d.coinsNeededForNextLevel
            animPercent = d.cleanBarPercent
            isAnimating = false
            return
        }

        let d = ProgressManager.shared.derivedProgress(forTotal: Int(displayedTotal))
        if d.currentLevel > animLevel {
            // Hit the cap of the level being left, pop, then resume next level.
            animPercent = 1.0
            animCoins = animNeeded
            pending = d
            pauseTicks = 13            // ~0.22s hold
            HapticManager.shared.impact(.light)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) { levelPulse = true }
        } else {
            animCoins = d.currentLevelCoins
            animNeeded = d.coinsNeededForNextLevel
            animPercent = d.cleanBarPercent
        }
    }
}
