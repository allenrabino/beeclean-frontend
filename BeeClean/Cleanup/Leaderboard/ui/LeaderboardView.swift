import SwiftUI

// MARK: - Leaderboard View
//
// One ladder, no toggle. Coins are the single ranking metric. Top 3
// get a gold/silver/bronze podium; ranks 4–100 use light list rows with coins
// and storage cleaned shown alongside. Current user gets an elevated card.

struct LeaderboardView: View {
    @StateObject private var vm = LeaderboardViewModel.shared
    @State private var detailEntry: LeaderboardEntry?

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                podium
                listSection
                if let selfEntry = vm.selfEntry, selfEntry.rank > 100 {
                    selfSticky(entry: selfEntry)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
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
        VStack(spacing: 10) {
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

    // MARK: Self Sticky

    private func selfSticky(entry: LeaderboardEntry) -> some View {
        VStack(spacing: 8) {
            Text("Your Rank")
                .font(.bodySmall)
                .foregroundColor(.mutedForeground)
            LeaderboardRow(entry: entry)
        }
        .padding(.top, 8)
    }
}

#Preview {
    NavigationStack {
        LeaderboardView()
    }
}
