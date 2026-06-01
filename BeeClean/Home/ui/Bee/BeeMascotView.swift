import SwiftUI

struct BeeMascotView: View {
    @ObservedObject var vm: BeeViewModel

    @State private var previousStage: BeeStage?
    @State private var previousOpacity = 0.0
    @State private var bounceScale: CGFloat = 1
    @State private var baseY: CGFloat = 0
    @State private var breatheScale: CGFloat = 1
    @State private var rotateAngle: Double = 0
    @State private var xOffset: CGFloat = 0
    @State private var glowOpacity: Double = 0.08
    @State private var blinkOpacity: Double = 0
    @State private var behaviorTask: Task<Void, Never>?

    @State private var lastStateToken = 0
    @State private var lastBehaviorToken = 0
    @State private var lastEvolutionToken = 0
    @State private var lastDevolutionToken = 0
    @State private var lastRewardToken = 0

    var body: some View {
        beeStack
            .offset(x: xOffset, y: baseY)
        .rotationEffect(.degrees(rotateAngle))
        .scaleEffect(bounceScale * breatheScale)
        .onAppear {
            startBaseIdle()
            startBehaviorLoop()
        }
        .onDisappear {
            behaviorTask?.cancel()
        }
        .onChange(of: vm.stage) { old, new in
            previousStage = old
            previousOpacity = 1
            withAnimation(.easeOut(duration: 0.45)) {
                previousOpacity = 0
            }
            runEvolveMotion(for: new)
        }
        .onChange(of: vm.stateToken) { _, token in
            guard token != lastStateToken else { return }
            lastStateToken = token
            reactToState(vm.state)
        }
        .onChange(of: vm.behaviorToken) { _, token in
            guard token != lastBehaviorToken else { return }
            lastBehaviorToken = token
            runBehavior(vm.activeBehavior)
        }
        .onChange(of: vm.evolutionToken) { _, token in
            guard token != lastEvolutionToken else { return }
            lastEvolutionToken = token
            runEvolveMotion(for: vm.stage)
        }
        .onChange(of: vm.devolutionToken) { _, token in
            guard token != lastDevolutionToken else { return }
            lastDevolutionToken = token
            runDevolveMotion(for: vm.stage)
        }
        .onChange(of: vm.rewardToken) { _, token in
            guard token != lastRewardToken else { return }
            lastRewardToken = token
            runCelebrationPulse()
        }
    }

    private var beeStack: some View {
        ZStack {
            glowCircle
            previousBeeLayer
            currentBeeImage
            BeeParticleOverlay(vm: vm)
            if vm.state == .thinking {
                ThinkingOrbitView(token: vm.orbitToken)
            }
            BlinkOverlay(opacity: blinkOpacity)
        }
    }

    private var glowCircle: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [Color(hex: "F4D44D").opacity(glowOpacity), Color(hex: "F4D44D").opacity(glowOpacity * 0.28), .clear],
                    center: .center,
                    startRadius: 20,
                    endRadius: 160
                )
            )
            .frame(width: 260, height: 260)
    }

    @ViewBuilder
    private var previousBeeLayer: some View {
        if let previousStage {
            Image(assetOrSymbol: previousStage.fallbackImageName)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .opacity(previousOpacity)
        }
    }

    private var currentBeeImage: some View {
        Image(assetOrSymbol: vm.stage.fallbackImageName)
            .resizable()
            .interpolation(.high)
            .antialiased(true)
            .scaledToFill()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
    }

    private func startBaseIdle() {
        withAnimation(.easeInOut(duration: 2.7).repeatForever(autoreverses: true)) {
            baseY = -5
        }
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            breatheScale = 1.014
        }
    }

    private func startBehaviorLoop() {
        behaviorTask?.cancel()
        behaviorTask = Task {
            while !Task.isCancelled {
                let ns = UInt64(Double.random(in: 6...12) * 1_000_000_000)
                try? await Task.sleep(nanoseconds: ns)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    vm.triggerRandomBehavior()
                }
            }
        }
    }

    private func reactToState(_ state: BeeMascotState) {
        switch state {
        case .idle:
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                bounceScale = 1
                xOffset = 0
                rotateAngle = 0
                glowOpacity = max(glowOpacity, 0.08)
            }
        case .reacting:
            withAnimation(.spring(response: 0.22, dampingFraction: 0.44)) {
                bounceScale = 1.08
                xOffset = 5
                rotateAngle = 2.5
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.7)) {
                    bounceScale = 1
                    xOffset = 0
                    rotateAngle = 0
                }
            }
        case .celebrating:
            runCelebrationPulse()
        case .thinking:
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                rotateAngle = 1.2
                glowOpacity = 0.18
            }
        case .encouraging:
            withAnimation(.spring(response: 0.34, dampingFraction: 0.48)) {
                baseY = -10
                bounceScale = 1.04
            }
        case .evolving:
            runEvolveMotion(for: vm.stage)
        case .devolving:
            runDevolveMotion(for: vm.stage)
        }
    }

    private func runBehavior(_ behavior: BeeIdleBehavior) {
        guard vm.state == .idle else { return }
        switch behavior {
        case .hoverSway:
            withAnimation(.easeInOut(duration: 0.7)) { rotateAngle = -1.6; xOffset = -4 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                withAnimation(.easeInOut(duration: 0.7)) { rotateAngle = 1.6; xOffset = 4 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.55) {
                withAnimation(.easeOut(duration: 0.35)) { rotateAngle = 0; xOffset = 0 }
            }
        case .blink:
            blinkOpacity = 1
            withAnimation(.easeOut(duration: 0.12)) { blinkOpacity = 0 }
        case .wingFlutter:
            withAnimation(.linear(duration: 0.08).repeatCount(4, autoreverses: true)) { rotateAngle = 2.6 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
                withAnimation(.easeOut(duration: 0.2)) { rotateAngle = 0 }
            }
        case .curiousTilt:
            withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) { rotateAngle = -5; xOffset = -6 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { rotateAngle = 0; xOffset = 0 }
            }
        case .smallBounce:
            withAnimation(.spring(response: 0.22, dampingFraction: 0.42)) { bounceScale = 1.08; baseY = -12 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) { bounceScale = 1; baseY = -5 }
            }
        case .glanceToMeter:
            withAnimation(.easeInOut(duration: 0.3)) { rotateAngle = 4; xOffset = 8; baseY = 2 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.48) {
                withAnimation(.easeOut(duration: 0.25)) { rotateAngle = 0; xOffset = 0; baseY = -5 }
            }
        case .playfulSpin:
            withAnimation(.spring(response: 0.65, dampingFraction: 0.82)) { rotateAngle = 360 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { rotateAngle = 0 }
        case .honeyCatch:
            withAnimation(.spring(response: 0.28, dampingFraction: 0.56)) { baseY = -16; xOffset = 10 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) { baseY = -5; xOffset = 0 }
            }
        case .hoverLoop:
            withAnimation(.easeInOut(duration: 0.45)) { xOffset = -10; baseY = -10 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                withAnimation(.easeInOut(duration: 0.45)) { xOffset = 10; baseY = -7 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                withAnimation(.easeOut(duration: 0.3)) { xOffset = 0; baseY = -5 }
            }
        }
    }

    private func runCelebrationPulse() {
        BeeHaptics.forReward(vm.rewardPulse)
        withAnimation(.spring(response: 0.22, dampingFraction: 0.4)) {
            bounceScale = 1.12
            glowOpacity = max(0.22, vm.glowIntensity)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            withAnimation(.easeOut(duration: 0.22)) {
                bounceScale = 0.95
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                bounceScale = 1
                glowOpacity = max(0.08, vm.glowIntensity * 0.55)
            }
        }
    }

    private func runEvolveMotion(for stage: BeeStage) {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.48)) {
            bounceScale = 0.94
            glowOpacity = max(0.26, vm.glowIntensity)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.74)) {
                bounceScale = 1.08
                rotateAngle = 1.5
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.46) {
            withAnimation(.easeOut(duration: 0.25)) {
                bounceScale = 1
                rotateAngle = 0
            }
        }
    }

    /// Inverse of `runEvolveMotion` — the bee sags and dims when it drops a
    /// stage. Used for both "scan found new clutter" regressions and the
    /// decay-timer regression that fires when a user goes days without
    /// cleaning. Intentionally low-energy — no sparkle, no rebound — so the
    /// user reads it as "I'm slipping" not "something broke."
    private func runDevolveMotion(for stage: BeeStage) {
        BeeHaptics.lightTap()
        // 1. Droop — gentle downward sag + slight forward tilt + dim glow.
        withAnimation(.easeOut(duration: 0.35)) {
            baseY = 6
            bounceScale = 0.94
            rotateAngle = -3
            glowOpacity = 0.03
        }
        // 2. Tiny head-shake at the bottom of the droop to sell the
        //    disappointment — slower + narrower than the celebrate wobble.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.40) {
            withAnimation(.easeInOut(duration: 0.22)) {
                rotateAngle = 2
                xOffset = -3
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.64) {
            withAnimation(.easeInOut(duration: 0.22)) {
                rotateAngle = -2
                xOffset = 3
            }
        }
        // 3. Settle back to the base idle position, but keep the glow dim
        //    so subsequent idle reads as "the bee's light is lower."
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                baseY = -5
                bounceScale = 1
                rotateAngle = 0
                xOffset = 0
                glowOpacity = max(0.05, vm.glowIntensity * 0.6)
            }
        }
    }
}

private struct BlinkOverlay: View {
    let opacity: Double
    var body: some View {
        Rectangle()
            .fill(Color.black.opacity(0.08))
            .opacity(opacity)
            .allowsHitTesting(false)
    }
}

private struct ThinkingOrbitView: View {
    let token: Int
    @State private var rotate = false

    var body: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { index in
                Circle()
                    .fill(Color(hex: "F7DA57").opacity(0.85))
                    .frame(width: 8, height: 8)
                    .offset(y: -86)
                    .rotationEffect(.degrees(Double(index) * 60))
            }
        }
        .rotationEffect(.degrees(rotate ? 360 : 0))
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                rotate = true
            }
        }
        .onChange(of: token) { _, _ in
            rotate = false
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                rotate = true
            }
        }
    }
}

// MARK: - CartoonBeeIcon
//
// A designed, fully vector cartoon bee — friendly face, striped body,
// wings, raised arms. Scales crisply at any size and needs no image asset,
// so it replaces the old `bee_card_mascot` / `BeeNameAvatar` PNGs (and the
// `ant.fill` fallback) on the Settings Pro card + bee-name rows. Lives in
// the Bee module so every surface draws the same mascot.

private enum BeePaint {
    static let ink = Color(hex: "3A2A0A")
    static let cheek = Color(hex: "FF9DB0")
    static var body: LinearGradient {
        LinearGradient(colors: [Color(hex: "FFE074"), Color(hex: "FBB534")],
                       startPoint: .top, endPoint: .bottom)
    }
    static var wing: LinearGradient {
        LinearGradient(colors: [.white.opacity(0.95), Color(hex: "D8EBFF").opacity(0.9)],
                       startPoint: .top, endPoint: .bottom)
    }
}

struct CartoonBeeIcon: View {
    var body: some View {
        GeometryReader { geo in
            layers(s: min(geo.size.width, geo.size.height))
        }
    }

    private func layers(s: CGFloat) -> some View {
        ZStack {
            wings(s: s)
            arms(s: s)
            antennae(s: s)
            BeeBody()
                .frame(width: s * 0.6, height: s * 0.62)
                .position(x: s * 0.5, y: s * 0.6)
        }
        .frame(width: s, height: s)
    }

    private func wings(s: CGFloat) -> some View {
        ZStack {
            beeWing(s: s, sign: -1)
            beeWing(s: s, sign: 1)
        }
    }

    private func arms(s: CGFloat) -> some View {
        ZStack {
            beeArm(s: s, sign: -1)
            beeArm(s: s, sign: 1)
        }
    }

    private func antennae(s: CGFloat) -> some View {
        ZStack {
            beeAntenna(s: s, sign: -1)
            beeAntenna(s: s, sign: 1)
        }
    }

    private func beeWing(s: CGFloat, sign: CGFloat) -> some View {
        let x: CGFloat = s * (0.5 + sign * 0.16)
        let y: CGFloat = s * 0.34
        let w: CGFloat = s * 0.34
        let h: CGFloat = s * 0.44
        let line: CGFloat = s * 0.016
        let angle: Double = Double(sign) * 26
        return Ellipse()
            .fill(BeePaint.wing)
            .overlay(Ellipse().strokeBorder(BeePaint.ink.opacity(0.5), lineWidth: line))
            .frame(width: w, height: h)
            .rotationEffect(.degrees(angle))
            .position(x: x, y: y)
    }

    private func beeArm(s: CGFloat, sign: CGFloat) -> some View {
        let x: CGFloat = s * (0.5 + sign * 0.27)
        let y: CGFloat = s * 0.5
        let w: CGFloat = s * 0.11
        let h: CGFloat = s * 0.24
        let line: CGFloat = s * 0.018
        let angle: Double = Double(sign) * 42
        return Capsule()
            .fill(BeePaint.body)
            .overlay(Capsule().strokeBorder(BeePaint.ink, lineWidth: line))
            .frame(width: w, height: h)
            .rotationEffect(.degrees(angle))
            .position(x: x, y: y)
    }

    private func beeAntenna(s: CGFloat, sign: CGFloat) -> some View {
        let dotX: CGFloat = s * (0.5 + sign * 0.17)
        let dotY: CGFloat = s * 0.13
        let dot: CGFloat = s * 0.07
        let line: CGFloat = s * 0.022
        return ZStack {
            AntennaPath(sign: sign)
                .stroke(BeePaint.ink, style: StrokeStyle(lineWidth: line, lineCap: .round))
            Circle()
                .fill(BeePaint.ink)
                .frame(width: dot, height: dot)
                .position(x: dotX, y: dotY)
        }
        .frame(width: s, height: s)
    }
}

private struct AntennaPath: Shape {
    let sign: CGFloat
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w = r.width, h = r.height
        func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: r.minX + x * w, y: r.minY + y * h)
        }
        p.move(to: P(0.5 + sign * 0.06, 0.34))
        p.addQuadCurve(to: P(0.5 + sign * 0.17, 0.14),
                       control: P(0.5 + sign * 0.22, 0.24))
        return p
    }
}

private struct BeeBody: View {
    var body: some View {
        GeometryReader { g in
            content(w: g.size.width, h: g.size.height)
        }
    }

    private func content(w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            Ellipse().fill(BeePaint.body)
            stripes(w: w, h: h)
            face(w: w, h: h)
            Ellipse().strokeBorder(BeePaint.ink, lineWidth: min(w, h) * 0.055)
        }
    }

    private func stripes(w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            Capsule().fill(BeePaint.ink)
                .frame(width: w * 1.2, height: h * 0.12)
                .rotationEffect(.degrees(-8))
                .position(x: w * 0.5, y: h * 0.62)
            Capsule().fill(BeePaint.ink)
                .frame(width: w * 1.2, height: h * 0.12)
                .rotationEffect(.degrees(-8))
                .position(x: w * 0.52, y: h * 0.82)
        }
        .clipShape(Ellipse())
    }

    private func face(w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            beeEye(w: w, h: h, sign: -1)
            beeEye(w: w, h: h, sign: 1)
            cheek(w: w, h: h, sign: -1)
            cheek(w: w, h: h, sign: 1)
            SmilePath()
                .stroke(BeePaint.ink,
                        style: StrokeStyle(lineWidth: min(w, h) * 0.035, lineCap: .round))
        }
    }

    private func cheek(w: CGFloat, h: CGFloat, sign: CGFloat) -> some View {
        let x: CGFloat = w * (0.5 + sign * 0.23)
        let y: CGFloat = h * 0.47
        let d: CGFloat = w * 0.14
        return Circle().fill(BeePaint.cheek.opacity(0.6))
            .frame(width: d, height: d)
            .position(x: x, y: y)
    }

    private func beeEye(w: CGFloat, h: CGFloat, sign: CGFloat) -> some View {
        let x: CGFloat = w * (0.5 + sign * 0.14)
        let y: CGFloat = h * 0.36
        let eyeW: CGFloat = w * 0.12
        let eyeH: CGFloat = h * 0.16
        let shine: CGFloat = w * 0.045
        let offX: CGFloat = -w * 0.02
        let offY: CGFloat = -h * 0.03
        return ZStack {
            Ellipse().fill(BeePaint.ink)
                .frame(width: eyeW, height: eyeH)
            Circle().fill(.white)
                .frame(width: shine, height: shine)
                .offset(x: offX, y: offY)
        }
        .position(x: x, y: y)
    }
}

private struct SmilePath: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w = r.width, h = r.height
        p.move(to: CGPoint(x: r.minX + w * 0.4, y: r.minY + h * 0.46))
        p.addQuadCurve(to: CGPoint(x: r.minX + w * 0.6, y: r.minY + h * 0.46),
                       control: CGPoint(x: r.minX + w * 0.5, y: r.minY + h * 0.55))
        return p
    }
}
