import SwiftUI
import Photos

// MARK: - Guided Cleanup View

struct GuidedCleanupView: View {
    @StateObject private var vm: GuidedCleanupViewModel
    @ObservedObject private var progressManager = ProgressManager.shared
    @ObservedObject private var hive = HiveStatsManager.shared
    @State private var showShareSheet: Bool = false

    // MARK: Checkpoint coin reward
    /// Coins earned by the checkpoint currently being celebrated. Drives the
    /// "+N" reward badge and the amount added to the header total.
    @State private var pendingCheckpointCoins = 0
    /// Added to the displayed header total during the fly animation so the user
    /// sees coins land BEFORE the real (monotonic) award fires on the CTA. Reset
    /// to 0 when the checkpoint clears — by then the real balance already
    /// includes it (continue) or it's correctly withdrawn (undo).
    @State private var celebrationCoinBoost = 0
    /// Frames (in the "guidedRoot" space) of the header coin pill (fly target)
    /// and the celebration reward badge (fly origin).
    @State private var headerCoinFrame: CGRect = .zero
    @State private var rewardBadgeFrame: CGRect = .zero
    @State private var flyingCoins = false

    /// Live header balance plus any in-flight celebration boost.
    private var displayedCoins: Int { hive.coinsBalance + celebrationCoinBoost }
    @Environment(\.dismiss) private var dismiss
    @State private var showReviewSheet = false
    @State private var reviewFilter: GuidedCleanupReviewFilter = .all
    @State private var dragOffset: CGSize = .zero
    /// True for the duration of a commit fly-off. Blocks touches + guards
    /// against a second commit firing mid-animation (the dropped/double
    /// swipe bug). Reset in the animation completion.
    @State private var isCommitting = false

    /// Drag distance (points) past which a release commits the swipe.
    /// Shared by the gesture's live threshold-tick and its commit branch.
    /// Lowered 100 → 70 so a modest drag commits — the deck was feeling
    /// stiff because it demanded a long haul before it would register.
    private static let commitThreshold: CGFloat = 70
    /// Predicted-throw distance (points) past which a quick flick commits
    /// even if the raw drag never reached `commitThreshold`.
    private static let flingThreshold: CGFloat = 280

    init(plan: TodayCleanupPlan, store: SimilarPhotosStore) {
        _vm = StateObject(wrappedValue: GuidedCleanupViewModel(plan: plan, store: store))
    }

    var body: some View {
        ZStack {
            glassBackdrop

            VStack(spacing: 0) {
                topBar
                if !vm.isPoolExhausted && !vm.tasks.isEmpty && !vm.isComplete {
                    checkpointProgressBar
                        .padding(.top, 12)
                }

                if vm.isPoolExhausted {
                    poolExhaustedView
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else if vm.isComplete {
                    completionView
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else if let checkpointIdx = vm.pendingCheckpointTaskIndex {
                    checkpointView(taskIndex: checkpointIdx)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else {
                    // Media is the hero: inset slightly from the screen
                    // edges so the rounded card reads as a contained
                    // surface rather than full-bleed.
                    cardStack
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .overlay(alignment: .bottomTrailing) {
                            // TikTok-style action column — anchored to
                            // the lower-right of the card, just above
                            // the storage badge.
                            //
                            // `.id(current.id)` forces SwiftUI to
                            // rebuild the rail's view tree per card so
                            // the heart/bookmark filled state is a
                            // fresh read of SavedFindsStore for THIS
                            // asset, not a stale view-tree carryover
                            // from the previous card.
                            if let current = vm.currentItem {
                                SwipeCardActionRail(
                                    assetId: current.id,
                                    context: railContext(for: current),
                                    onShareRequested: { showShareSheet = true }
                                )
                                .id(current.id)
                                .padding(.trailing, 24)
                                .padding(.bottom, 72)
                            }
                        }
                    Spacer(minLength: 16)
                    actionButtons
                        .padding(.bottom, 24)
                }
            }

        }
        .navigationBarHidden(true)
        .hidesBottomNavBar()
        .coordinateSpace(name: "guidedRoot")
        .overlay { coinFlightOverlay }
        .onPreferenceChange(CoinFrameKey.self) { headerCoinFrame = $0 }
        .onChange(of: vm.pendingCheckpointTaskIndex) { _, idx in
            handleCheckpointChange(idx)
        }
        .sheet(isPresented: $showShareSheet) {
            if let current = vm.currentItem {
                MediaShareSheet(
                    assetId: current.id,
                    onDismiss: { showShareSheet = false }
                )
                .presentationDetents([.height(420)])
                .presentationDragIndicator(.hidden)
            }
        }
        // Catch every exit (back arrow, interactive swipe-back) so coins for
        // finished checkpoints are banked even if the user never hits a CTA.
        // Idempotent — already-credited checkpoints are skipped.
        .onDisappear {
            vm.awardCompletedCheckpoints()
            recordCompletionIfNeeded()
        }
        // SINGLE fullScreenCover on this view. A second `.fullScreenCover`
        // here (the old NewTaskLauncher one) silently shadowed this one —
        // SwiftUI only honors one cover per view — so the trash button set
        // `showReviewSheet = true` but nothing ever presented. The launcher
        // cover was dead anyway (`showNewTaskLauncher` was never set true),
        // so it's gone and the review sheet now works.
        .fullScreenCover(isPresented: $showReviewSheet) {
            reviewSheet
        }
        .animation(.easeInOut(duration: 0.3), value: vm.isComplete)
        .animation(.easeInOut(duration: 0.3), value: vm.pendingCheckpointTaskIndex)
        .animation(.easeInOut(duration: 0.3), value: vm.isPoolExhausted)
        .onAppear {
            // Take over the audio session — pauses Spotify / YouTube /
            // podcasts so our cleanup video previews play uninterrupted.
            // Released in .onDisappear; reference-counted in the
            // AudioSessionManager so nested swipe flows don't release
            // each other's hold.
            AudioSessionManager.shared.requestExclusivePlayback()
            // #region agent log
            AppDebugLog.write(
                location: "GuidedCleanupView.onAppear",
                message: "guided cleanup session started",
                hypothesisId: "A",
                data: [
                    "tasksCount": vm.tasks.count,
                    "roundGoalBytes": vm.roundGoalBytes,
                    "itemsCount": vm.items.count
                ]
            )
            // #endregion
        }
        .onDisappear {
            AudioSessionManager.shared.releaseExclusivePlayback()
        }
    }

    // MARK: - Pool Exhausted (All Caught Up)

    private var poolExhaustedView: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color(hex: "3A6B3A").opacity(0.12))
                    .frame(width: 100, height: 100)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 56))
                    .foregroundColor(Color(hex: "3A6B3A"))
            }

            VStack(spacing: 6) {
                Text("You're all caught up")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text("We'll let you know when there's more to review.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color(hex: "3A6B3A"))
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous))
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.horizontal, 40)
            .padding(.top, 12)

            Spacer()
        }
    }

    // MARK: - Glass Backdrop
    // Matches Email / Settings / Compress screens.
    private var glassBackdrop: some View {
        LinearGradient(
            stops: [
                .init(color: Color(hex: "DDE1F2"), location: 0.0),
                .init(color: Color(hex: "E3E6EE"), location: 0.45),
                .init(color: Color(hex: "EDEEEF"), location: 1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button {
                HapticManager.shared.impact(.light)
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 40, height: 40)
                    .background(Color.white)
                    .clipShape(Circle())
                    // Whole circle is the hit target (not just the opaque
                    // glyph), so the back tap registers reliably.
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .zIndex(1)

            Spacer()

            HStack(spacing: 8) {
                coinPill
                Text("Quick Cleanup")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }

            Spacer()

            if !vm.isComplete {
                HStack(spacing: 10) {
                    // Undo — icon-only, sits beside the trash so the
                    // bottom row stays a clean REMOVE / SAVE commit.
                    Button {
                        // undoLast() already fires a .light impact — don't
                        // double-buzz by firing a second one here.
                        vm.undoLast()
                    } label: {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(vm.canUndo ? .primary : Color(hex: "C7C7CC"))
                            .frame(width: 40, height: 40)
                            .background(Color.white)
                            .clipShape(Circle())
                            .contentShape(Circle())
                    }
                    .disabled(!vm.canUndo)
                    .buttonStyle(ScaleButtonStyle())

                    Button {
                        openReviewSheet(filter: .all)
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "trash")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                                .frame(width: 36, height: 36)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.06), radius: 4, y: 2)

                            if vm.totalMarked > 0 {
                                Text("\(vm.totalMarked)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(minWidth: 18, minHeight: 18)
                                    .background(Color.red)
                                    .clipShape(Capsule())
                                    .offset(x: 6, y: -6)
                            }
                        }
                    }
                }
            } else {
                Color.clear
                    .frame(width: 36, height: 36)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: - Header Coin Pill

    private var coinPill: some View {
        HStack(spacing: 4) {
            CoinBadge(size: 16)
            Text("\(displayedCoins)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .contentTransition(.numericText())
                .monospacedDigit()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.white)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        .background(
            GeometryReader { p in
                Color.clear.preference(
                    key: CoinFrameKey.self,
                    value: p.frame(in: .named("guidedRoot"))
                )
            }
        )
    }

    // MARK: - Coin Flight Overlay
    // Coins launched from the celebration reward badge that arc up into the
    // header pill, selling "added to your total." Driven by `flyingCoins`.
    @ViewBuilder
    private var coinFlightOverlay: some View {
        if flyingCoins, rewardBadgeFrame != .zero, headerCoinFrame != .zero {
            let start = CGPoint(x: rewardBadgeFrame.midX, y: rewardBadgeFrame.midY)
            let end = CGPoint(x: headerCoinFrame.midX, y: headerCoinFrame.midY)
            ForEach(0..<6, id: \.self) { i in
                FlyingCoin(start: start, end: end, delay: Double(i) * 0.05)
            }
            .allowsHitTesting(false)
        }
    }

    // MARK: - Checkpoint Progress Bar (shared yellow tracker)

    private var checkpointProgressBar: some View {
        let filled = vm.completedCheckpointNodes
        let nodeCount = vm.tasks.count + 1
        return GuidedCleanupCheckpointProgressView(
            tasks: vm.tasks,
            isNodeComplete: { idx in
                filled > 0 && idx <= filled
            },
            isNodeActive: { idx in
                guard !vm.isComplete else { return false }
                if vm.pendingCheckpointTaskIndex != nil { return false }
                if filled == 0 { return idx == 0 }
                let next = filled + 1
                return idx == next && next < nodeCount
            }
        )
    }

    // MARK: - Current Category Pill

    private var currentCategoryPill: some View {
        Group {
            if let item = vm.currentItem {
                let reviewed = vm.reviewedCount(forTask: item.taskIndex)
                let total = vm.totalCount(forTask: item.taskIndex)

                HStack(spacing: 8) {
                    Image(systemName: categoryIcon(for: item.category))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(iconColor(for: item.category))
                    Text(categoryLabel(for: item.category))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("\(reviewed + 1)/\(total)")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                    Text(CleanupRound.formatBytes(item.fileSize))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.white)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
            }
        }
    }

    // MARK: - Saved-Find Context Mapping

    /// Map a guided-cleanup item to the SavedFindContext the heart /
    /// bookmark rail needs. Picks the matching SavedFindSourceCategory
    /// per CleanupTaskCategory so saves land in the right bucket.
    private func railContext(for item: GuidedItem) -> SavedFindContext {
        let mediaType: SavedFindMediaType = item.category.isVideoCategory ? .video : .photo
        let sourceCategory: SavedFindSourceCategory = {
            switch item.category {
            case .duplicatePhotos:    return .duplicates
            case .similarPhotos:      return .similarPhotos
            case .similarScreenshots: return .similarScreenshots
            case .screenshots:        return .screenshots
            case .blurryPhotos:       return .blurredPhotos
            case .otherPhotos:        return .otherPhotos
            case .similarVideos:      return .similarVideos
            case .screenRecordings:   return .screenRecordings
            case .shortRecordings:    return .shortRecordings
            case .longVideos:         return .longVideos
            case .promoEmails:        return .otherPhotos // unreachable in photo/video flow
            }
        }()
        return SavedFindContext(mediaType: mediaType, sourceCategory: sourceCategory)
    }

    // MARK: - Card Stack

    private var cardStack: some View {
        GeometryReader { geo in
            // Full-bleed: media spans the entire band edge-to-edge. No
            // horizontal padding, no internal cap.
            let w = geo.size.width
            let h = geo.size.height

            if w > 0, h > 0 {
                let size = CGSize(width: w, height: h)
                ZStack {
                    // Active card only. The next 1–2 items are pre-decoded
                    // into AssetThumbnailCache via `prefetchUpcoming` so the
                    // hard-cut to the next card paints synchronously — but
                    // they are NEVER mounted to the view tree while the
                    // active card is on screen. No peek, no offset, no
                    // shadow, no edge visible behind the top card.
                    if let current = vm.currentItem {
                        cardView(item: current, size: size)
                            // Key the card to its asset id so each swipe hard-
                            // cuts to a FRESH card (fresh SwipeCardMedia + state)
                            // instead of SwiftUI recycling the prior view — the
                            // fix for stale/blank cards. Mirrors MediaSwipeView.
                            .id(current.id)
                            .offset(dragOffset)
                            .rotationEffect(.degrees(Double(dragOffset.width / 20)))
                            .overlay(swipeOverlay(size: size))
                            .allowsHitTesting(!isCommitting)
                            .gesture(swipeGesture)
                            .transition(.identity)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    prefetchUpcoming(size: size)
                }
                .onChange(of: vm.currentIndex) { _, _ in
                    prefetchUpcoming(size: size)
                }
            }
        }
    }

    /// Decode the next few thumbnails into `AssetThumbnailCache` without
    /// mounting them, so the next card's `PhotoThumbnailView` gets a
    /// SYNCHRONOUS cache hit on mount and paints on the first frame — no
    /// blank flash after the hard cut.
    private func prefetchUpcoming(size: CGSize) {
        let start = vm.currentIndex + 1
        guard start < vm.items.count else { return }
        let end = min(start + 3, vm.items.count)
        let ids = vm.items[start..<end].map { $0.id }
        // CRITICAL: warm the cache at the EXACT size the card renders at —
        // `SwipeCardMedia`'s `PhotoThumbnailView` requests 2× (retina), and
        // the cache key is `assetId@WxH`. Prefetching at the 1× point size
        // (the old bug) produced a different key, so the prefetch never hit
        // and every card decoded from scratch on mount = the blank flash.
        let renderSize = CGSize(width: size.width * 2, height: size.height * 2)
        // Synchronous Core Data fetch — keep it OFF the main thread so the
        // active swipe doesn't hitch while we warm the next cards' cache.
        Task.detached(priority: .utility) {
            let fetched = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
            var collected: [PHAsset] = []
            fetched.enumerateObjects { asset, _, _ in collected.append(asset) }
            let assets = collected
            await MainActor.run {
                AssetThumbnailCache.shared.prefetch(assets, size: renderSize, limit: 3)
            }
        }
    }

    private func cardView(item: GuidedItem, size: CGSize) -> some View {
        ZStack(alignment: .top) {
            // Cover-fit: media fills the full band, cropping as needed.
            // SwipeCardMedia auto-detects video vs photo — videos mount an
            // AVPlayerLooper-backed AutoPlayingVideoCard (looped, audio on
            // with a mute toggle), photos render via PhotoThumbnailView. Because the
            // parent `cardStack` keys the active card on `vm.currentItem`,
            // a fresh SwipeCardMedia is constructed every swipe, so the
            // new asset's player kicks off the moment it appears.
            SwipeCardMedia(
                assetId: item.id,
                cardSize: size,
                // Videos play with sound (+ a mute toggle), matching the
                // standalone swipe deck. The session is `.playback`, so
                // audio works even on silent. Was previously muted, which
                // is why Quick Cleanup had no sound.
                audioControlsEnabled: true
            )
            .frame(width: size.width, height: size.height)
            .clipped()

            // Floating pills — moved to the TOP of the card so the
            // bottom edge is clear for the TikTok-style action rail and
            // its share-sheet readability.
            HStack {
                Text(categoryLabel(for: item.category))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Capsule())

                Spacer()

                Text(CleanupRound.formatBytes(item.fileSize))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)

            // Best shot badge — moved to BOTTOM-left now that the
            // category / size pills migrated to the top edge. Keeps the
            // top row clean (just two pills) and gives the badge its
            // own corner so it doesn't crowd them.
            if item.isBest {
                VStack {
                    Spacer()
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                            Text("Best Shot")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(Color(hex: "996515"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(hex: "FFD700").opacity(0.85))
                        .clipShape(Capsule())
                        .padding(.horizontal, 16)
                        .padding(.bottom, 14)

                        Spacer()
                    }
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    /// 0…1 ramp tied to swipe distance — drives both stamp opacity AND
    /// the bottom-label glow intensity so the on-card stamp and the
    /// bottom button always pulse in lockstep with the drag.
    private var removeIntensity: Double {
        dragOffset.width < 0 ? Double(min(abs(dragOffset.width) / Self.commitThreshold, 1.0)) : 0
    }
    private var keepIntensity: Double {
        dragOffset.width > 0 ? Double(min(dragOffset.width / Self.commitThreshold, 1.0)) : 0
    }

    private func swipeOverlay(size: CGSize) -> some View {
        // Just the colored wash — no repeated word stamp on the card. Swipe
        // LEFT washes RED, swipe RIGHT washes GREEN, intensity ramping with
        // the drag distance. The bottom REMOVE/SAVE labels carry the wording.
        ZStack {
            if dragOffset.width < 0 {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.red.opacity(removeIntensity * 0.45))
            }
            if dragOffset.width > 0 {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.green.opacity(keepIntensity * 0.45))
            }
        }
        .frame(width: size.width, height: size.height)
        .allowsHitTesting(false)
    }

    private var swipeGesture: some Gesture {
        // minimumDistance 1 → the card starts tracking the finger almost
        // immediately (there's no competing tap gesture on the guided card),
        // so a swipe never feels like it "didn't take". 1:1 follow on change.
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                // Light tick the instant the drag crosses into the commit
                // zone (and only on that transition) so the user *feels*
                // when a release will register — fires once per crossing,
                // never every frame.
                let wasPastThreshold = abs(dragOffset.width) > Self.commitThreshold
                let isPastThreshold = abs(value.translation.width) > Self.commitThreshold
                if isPastThreshold && !wasPastThreshold {
                    HapticManager.shared.impact(.light, intensity: 0.6)
                }
                dragOffset = value.translation
            }
            .onEnded { value in
                // Ignore a release that lands while a commit fly-off is still
                // animating — prevents the deck advancing twice / dropping a
                // swipe on rapid flicks.
                guard !isCommitting else { return }
                // Commit on a far-enough drag OR a quick flick — whichever
                // lands first. `predictedEndTranslation` is how far the throw
                // would carry, so a fast flick commits even on a short drag.
                // This is what makes the deck feel Tinder-light instead of
                // forcing a long, deliberate haul to the threshold every time.
                let translation = value.translation.width
                let predicted = value.predictedEndTranslation.width
                if translation < -Self.commitThreshold || predicted < -Self.flingThreshold {
                    commitSwipe(.left, dropHeight: value.translation.height)
                } else if translation > Self.commitThreshold || predicted > Self.flingThreshold {
                    commitSwipe(.right, dropHeight: value.translation.height)
                } else {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                        dragOffset = .zero
                    }
                }
            }
    }

    /// Single commit path shared by the drag gesture and the bottom buttons:
    /// fire the commit haptic immediately, fling the card off-screen, then
    /// advance the deck once it's gone. `dropHeight` preserves the vertical
    /// component of a diagonal throw so the exit arc matches the finger.
    private func commitSwipe(_ direction: SwipeDirection, dropHeight: CGFloat = 0) {
        // One commit at a time. The flag also blocks card touches via
        // `.allowsHitTesting(!isCommitting)` so the fly-off can't be hijacked.
        guard !isCommitting else { return }
        isCommitting = true
        HapticManager.shared.quickAccessCommit()
        let endX: CGFloat = direction == .left ? -600 : 600
        // Animate the fly-off, then advance the deck in the COMPLETION (not a
        // racey asyncAfter). When `vm` advances, `current.id` changes and the
        // next card hard-cuts in at offset .zero with fresh state.
        withAnimation(.easeOut(duration: 0.2)) {
            dragOffset = CGSize(width: endX, height: dropHeight)
        } completion: {
            dragOffset = .zero
            if direction == .left { vm.swipeLeft() } else { vm.swipeRight() }
            isCommitting = false
        }
    }

    // MARK: - Action Buttons (SwipeWipe-style text labels)
    //
    // REMOVE on the left, SAVE on the right — pure text, no chrome —
    // so the card itself is the focal point. Each label pulses a
    // colored glow proportional to the active swipe distance: REMOVE
    // lights up red on left drag, SAVE lights up green on right drag.
    // Undo moved to the top bar (next to the trash) so the bottom row
    // is a clean two-action commit.
    private var actionButtons: some View {
        // Always-visible, static words pinned to the far edges (Tinder-
        // style). They never fade — instead each word cross-fades from the
        // cleanup-bar yellow toward its action color as the card is dragged:
        // REMOVE → red on a left swipe, SAVE → green on a right swipe,
        // mirroring the card's own highlight wash.
        HStack {
            Button(action: triggerSwipeLeft) {
                swipeWord("REMOVE", tint: .red, intensity: removeIntensity)
            }
            .disabled(vm.currentItem == nil)
            .buttonStyle(ScaleButtonStyle())

            Spacer()

            Button(action: triggerSwipeRight) {
                swipeWord("SAVE", tint: .green, intensity: keepIntensity)
            }
            .disabled(vm.currentItem == nil)
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal, 24)
    }

    /// A static action word that cross-fades from cleanup-bar yellow to
    /// `tint` as the matching swipe ramps 0→1. Two stacked Texts so the
    /// transition is a smooth opacity blend — no Color interpolation needed.
    private func swipeWord(_ title: String, tint: Color, intensity: Double) -> some View {
        ZStack {
            Text(title).foregroundColor(Color(hex: "FFC648"))
            Text(title).foregroundColor(tint).opacity(intensity)
        }
        .font(.system(size: 18, weight: .heavy, design: .rounded))
        .tracking(0.3)
        .contentShape(Rectangle())
    }

    private func triggerSwipeLeft() { commitSwipe(.left) }

    private func triggerSwipeRight() { commitSwipe(.right) }

    // MARK: - Checkpoint View

    private func checkpointView(taskIndex: Int) -> some View {
        GuidedCleanupCelebrationView(
            content: vm.checkpointCelebration(for: taskIndex),
            onPrimary: {
                // Mutates VM + awards coins (publishes into HiveStatsManager).
                // Must NOT run inside `withAnimation` — that executes within the
                // view-update transaction and trips "Publishing changes from
                // within view updates". The celebration→cards transition still
                // animates via `.animation(_:value: vm.pendingCheckpointTaskIndex)`.
                vm.continueAfterCheckpoint()
            },
            coinBoost: vm.coinPreview(forTask: taskIndex),
            footer: { coinRewardBadge }
        )
    }

    /// "+N 🪙" badge shown on the celebration card; pops in, then its coins fly
    /// up to the header pill. Hidden once the coins have launched.
    private var coinRewardBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(hex: "FFC636"))
            Text("+\(pendingCheckpointCoins)")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundColor(.primary)
            CoinBadge(size: 22)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(Color.white)
        .clipShape(Capsule())
        .shadow(color: Color(hex: "FFC636").opacity(0.35), radius: 10, y: 3)
        .opacity(flyingCoins ? 0 : 1)
        .scaleEffect(flyingCoins ? 0.6 : 1)
        .background(
            GeometryReader { p in
                Color.clear.preference(
                    key: RewardFrameKey.self,
                    value: p.frame(in: .named("guidedRoot"))
                )
            }
        )
        .onPreferenceChange(RewardFrameKey.self) { rewardBadgeFrame = $0 }
    }

    /// Orchestrates the reward sequence as the celebrated checkpoint changes.
    private func handleCheckpointChange(_ idx: Int?) {
        guard let idx else {
            // Checkpoint cleared (continue → real award already landed; or undo
            // → nothing awarded). Drop the boost; the live balance is correct.
            celebrationCoinBoost = 0
            flyingCoins = false
            pendingCheckpointCoins = 0
            return
        }
        pendingCheckpointCoins = vm.coinPreview(forTask: idx)
        celebrationCoinBoost = 0
        flyingCoins = false
        guard pendingCheckpointCoins > 0 else { return }
        // Beat for the badge to pop in, then launch the coins; tick the header
        // total up as they land.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            guard vm.pendingCheckpointTaskIndex == idx else { return }
            withAnimation(.easeInOut(duration: 0.45)) { flyingCoins = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                guard vm.pendingCheckpointTaskIndex == idx else { return }
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    celebrationCoinBoost = pendingCheckpointCoins
                }
            }
        }
    }

    // MARK: - Shuffling System completion

    /// Record the finished session to the persistent cleanup history and rotate
    /// the active task forward — exactly once per session (guarded in the VM).
    /// Fires from the completion screen, the back arrow, and onDisappear so any
    /// exit with real work done is captured.
    private func recordCompletionIfNeeded() {
        guard vm.isComplete || vm.totalCoinsEarned > 0 else { return }
        guard vm.markCompletionRecorded() else { return }
        let result = CompletedTaskResult(
            taskTitle: "Quick Cleanup",
            taskType: "quick_cleanup",
            category: (vm.dominantSessionCategory ?? .otherPhotos).rawValue,
            mbReviewed: Double(vm.sessionBytesCleaned) / 1_000_000,
            coinsEarned: vm.totalCoinsEarned,
            levelAtCompletion: ProgressManager.shared.currentLevel,
            assetCount: vm.sessionDeletedCount
        )
        Task { await CleanupTaskManager.shared.completeActiveTask(result: result) }
    }

    // MARK: - Completion View (Task Summary)

    private var completionView: some View {
        GuidedCleanupCompletionView(
            vm: vm,
            onBackToDashboard: { finishAndReturnToDashboard() },
            onStartNewTask: { startNewTaskFromCompletion() },
            onPhotoCardTap: { openReviewSheet(filter: .photos) },
            onVideoCardTap: { openReviewSheet(filter: .videos) },
            isPrimaryDisabled: vm.isDeleting || vm.completionDeletionPhase != .idle
        )
    }

    private func openReviewSheet(filter: GuidedCleanupReviewFilter) {
        reviewFilter = filter
        // #region agent log
        AppDebugLog.write(
            location: "GuidedCleanupView.openReviewSheet",
            message: "review sheet requested",
            hypothesisId: "H3",
            data: [
                "filter": String(describing: filter),
                "isComplete": vm.isComplete,
                "totalMarked": vm.totalMarked,
                "photoCount": vm.markedPhotoCount,
                "videoCount": vm.markedVideoCount
            ]
        )
        // #endregion
        showReviewSheet = true
    }

    /// Shows iOS delete dialog first; in-place completion animations after confirm.
    private func finishAndReturnToDashboard() {
        guard vm.completionDeletionPhase == .idle, !vm.isDeleting else { return }
        if vm.totalMarked == 0 {
            vm.clearSessionState()
            dismiss()
            return
        }
        runCompletionDeletion(filter: .all)
    }

    /// Deletes marked media (if any) then loads a fresh cleanup batch in place
    /// — stays inside the cover instead of dismissing to the homepage.
    private func startNewTaskFromCompletion() {
        guard vm.completionDeletionPhase == .idle, !vm.isDeleting else { return }
        if vm.totalMarked == 0 {
            recordCompletionIfNeeded()
            vm.startNewTask()
            return
        }
        runCompletionDeletion(filter: .all) {
            recordCompletionIfNeeded()
            vm.startNewTask()
        }
    }

    private func runCompletionDeletion(
        filter: GuidedCleanupReviewFilter,
        onFinish: (() -> Void)? = nil
    ) {
        guard vm.completionDeletionPhase == .idle else { return }
        showReviewSheet = false

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 260_000_000)

            vm.onPhotoLibraryDeleteConfirmed = {
                vm.beginDeletionStatusMessages(for: filter)
                // #region agent log
                AppDebugLog.write(
                    location: "GuidedCleanupView.onPhotoLibraryDeleteConfirmed",
                    message: "PhotoKit confirmed, in-place animations started",
                    hypothesisId: "H5",
                    data: ["filter": String(describing: filter)]
                )
                // #endregion
            }

            // #region agent log
            AppDebugLog.write(
                location: "GuidedCleanupView.runCompletionDeletion",
                message: "awaiting PhotoKit delete dialog",
                hypothesisId: "H5",
                data: ["filter": String(describing: filter)]
            )
            // #endregion

            let success = await deleteForFilter(filter)
            vm.onPhotoLibraryDeleteConfirmed = nil

            if success {
                vm.showCompletionDeletionSuccess()
                HapticManager.shared.notify(.success)
                try? await Task.sleep(nanoseconds: 1_100_000_000)
                if let onFinish {
                    onFinish()
                } else {
                    vm.clearSessionState()
                    dismiss()
                }
            } else {
                vm.resetCompletionDeletionUI()
            }
        }
    }

    private func deleteForFilter(_ filter: GuidedCleanupReviewFilter) async -> Bool {
        switch filter {
        case .all:
            return await vm.deleteAllMarked()
        case .photos:
            return await vm.deleteMarked { $0.category.isPhotoCategory }
        case .videos:
            return await vm.deleteMarked { $0.category.isVideoCategory }
        }
    }

    // MARK: - Review Sheet

    private var reviewSheet: some View {
        NavigationView {
            ZStack {
                glassBackdrop

                if filteredMarkedItems.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "trash.slash")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No items to delete")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                } else {
                    VStack(spacing: 0) {
                        // Summary header
                        HStack {
                            Text("\(filteredMarkedItems.count) item\(filteredMarkedItems.count == 1 ? "" : "s")")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(CleanupRound.formatBytes(filteredBytesMarked))
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: "3A6B3A"))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)

                        ScrollView {
                            let columns = [
                                GridItem(.flexible(), spacing: 3),
                                GridItem(.flexible(), spacing: 3),
                                GridItem(.flexible(), spacing: 3)
                            ]

                            LazyVGrid(columns: columns, spacing: 3) {
                                ForEach(filteredMarkedItems) { item in
                                    Button {
                                        vm.unmarkItem(item.id)
                                    } label: {
                                        ZStack(alignment: .topTrailing) {
                                            PhotoThumbnailView(
                                                assetIdentifier: item.id,
                                                size: CGSize(width: 130, height: 130),
                                                contentMode: .fill
                                            )
                                            .frame(height: 130)
                                            .clipped()

                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(.white)
                                                .shadow(radius: 2)
                                                .padding(6)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 3)
                        }

                        // Delete All button
                        Button {
                            runCompletionDeletion(filter: reviewFilter)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "trash.fill")
                                Text("Delete All (\(filteredMarkedItems.count))")
                            }
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.red)
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous))
                        }
                        .disabled(vm.completionDeletionPhase != .idle)
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationTitle(reviewSheetTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showReviewSheet = false
                    }
                    .font(.system(size: 16, weight: .semibold))
                }
            }
        }
    }

    private var markedItems: [GuidedItem] {
        vm.items.filter { vm.markedForDeletion.contains($0.id) }
    }

    private var filteredMarkedItems: [GuidedItem] {
        switch reviewFilter {
        case .all:
            return markedItems
        case .photos:
            return markedItems.filter { $0.category.isPhotoCategory }
        case .videos:
            return markedItems.filter { $0.category.isVideoCategory }
        }
    }

    private var filteredBytesMarked: Int64 {
        filteredMarkedItems.reduce(Int64(0)) { $0 + $1.fileSize }
    }

    private var reviewSheetTitle: String {
        switch reviewFilter {
        case .all: return "Review Deletions"
        case .photos: return "Photos to Delete"
        case .videos: return "Videos to Delete"
        }
    }

    // MARK: - Helpers

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

    private func categoryIcon(for category: CleanupTaskCategory) -> String {
        switch category {
        case .duplicatePhotos: return "doc.on.doc.fill"
        case .similarPhotos: return "photo.on.rectangle"
        case .similarScreenshots: return "rectangle.on.rectangle"
        case .screenshots: return "rectangle.on.rectangle"
        case .blurryPhotos: return "camera.metering.unknown"
        case .similarVideos: return "film.fill"
        case .screenRecordings: return "record.circle"
        case .shortRecordings: return "video.fill"
        case .longVideos: return "film.fill"
        case .otherPhotos: return "photo.fill"
        case .promoEmails: return "envelope.fill"
        }
    }

    private func categoryLabel(for category: CleanupTaskCategory) -> String {
        switch category {
        case .duplicatePhotos: return "Duplicate"
        case .similarPhotos: return "Similar"
        case .similarScreenshots: return "Screenshot"
        case .screenshots: return "Screenshot"
        case .blurryPhotos: return "Blurry"
        case .similarVideos: return "Video"
        case .screenRecordings: return "Screen Rec"
        case .shortRecordings: return "Short Video"
        case .longVideos: return "Large Video"
        case .otherPhotos: return "Photo"
        case .promoEmails: return "Email"
        }
    }
}

// MARK: - Coin reward animation support

/// Frame of the header coin pill in the "guidedRoot" space (fly target).
private struct CoinFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let next = nextValue()
        if next != .zero { value = next }
    }
}

/// Frame of the celebration reward badge in the "guidedRoot" space (fly origin).
private struct RewardFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let next = nextValue()
        if next != .zero { value = next }
    }
}

/// A single coin that arcs from `start` to `end`, fading + shrinking on arrival.
private struct FlyingCoin: View {
    let start: CGPoint
    let end: CGPoint
    let delay: Double

    @State private var progress: CGFloat = 0

    var body: some View {
        let t = progress
        // Slight upward arc via an eased control on the Y midpoint.
        let x = start.x + (end.x - start.x) * t
        let arc = -60 * sin(Double(t) * .pi)
        let y = start.y + (end.y - start.y) * t + CGFloat(arc)
        CoinBadge(size: 20)
            .scaleEffect(1 - 0.5 * t)
            .opacity(t < 0.85 ? 1 : Double(1 - (t - 0.85) / 0.15))
            .position(x: x, y: y)
            .onAppear {
                withAnimation(.easeIn(duration: 0.5).delay(delay)) {
                    progress = 1
                }
            }
    }
}
