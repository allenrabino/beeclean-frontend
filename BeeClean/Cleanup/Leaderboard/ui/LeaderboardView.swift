import SwiftUI

// MARK: - Leaderboard View
//
// One ladder, no toggle. Coins are the single ranking metric. Storage
// freed shows alongside as the secondary stat. Top 3 get a trophy
// podium; ranks 4–100 wear the glass-polish row treatment.

struct LeaderboardView: View {
    @StateObject private var vm = LeaderboardViewModel.shared
    @State private var detailEntry: LeaderboardEntry?

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                header
                RelativeRankCard(selfEntry: vm.selfEntry)
                podium
                listSection
                if let selfEntry = vm.selfEntry, selfEntry.rank > 100 {
                    selfSticky(entry: selfEntry)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(Color.background.ignoresSafeArea())
        .navigationTitle("Leaderboard")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await vm.refresh() }
        .navigationDestination(item: $detailEntry) { entry in
            LeaderboardDetailView(entry: entry)
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(spacing: 6) {
            Text("Top 100 Cleaners")
                .font(.titleLarge)
                .foregroundColor(.foreground)
            Text("Ranked by coins · storage freed shown alongside")
                .font(.bodySmall)
                .foregroundColor(.mutedForeground)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 8)
    }

    // MARK: Podium

    private var podium: some View {
        LeaderboardPodiumView(
            entries: Array(vm.entries.prefix(3)),
            style: .full,
            onSelect: { detailEntry = $0 }
        )
    }

    // MARK: List 4..100

    private var listSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(LinearGradient.honeyGradient)
                Text("Top 100 Hive")
                    .font(.labelMedium)
                    .foregroundColor(.foreground)
                Spacer()
            }
            .padding(.horizontal, 2)

            VStack(spacing: 8) {
                ForEach(Array(vm.entries.dropFirst(3).prefix(97))) { entry in
                    Button {
                        detailEntry = entry
                    } label: {
                        LeaderboardRow(entry: entry)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Self Sticky

    private func selfSticky(entry: LeaderboardEntry) -> some View {
        VStack(spacing: 6) {
            Text("Your Rank")
                .font(.bodySmall)
                .foregroundColor(.mutedForeground)
            LeaderboardRow(entry: entry)
        }
        .padding(.top, 12)
    }
}

#Preview {
    NavigationStack {
        LeaderboardView()
    }
}
