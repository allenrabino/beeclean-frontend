import SwiftUI

// MARK: - Leaderboard View
//
// One ladder, no toggle. Coins are the single ranking metric. Top 3
// get a gold/silver/bronze podium; ranks 4–100 use light list rows with coins
// and storage cleaned shown alongside. Current user gets an elevated card.

struct LeaderboardView: View {
    @ObservedObject private var auth = AuthService.shared
    @StateObject private var vm = LeaderboardViewModel.shared
    @State private var detailEntry: LeaderboardEntry?

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                statusBanner
                if vm.isLoading && vm.entries.isEmpty {
                    loadingPlaceholder
                } else if vm.entries.isEmpty {
                    emptyPlaceholder
                } else {
                    podium
                    listSection
                    if let selfEntry = vm.selfEntry, selfEntry.rank > 100 {
                        selfSticky(entry: selfEntry)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 24)
        }
        .background(Color.background.ignoresSafeArea())
        .navigationTitle("Leaderboard")
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.refresh() }
        .refreshable { await vm.refresh() }
        .onChange(of: auth.isAuthenticated) { _, isAuthed in
            if isAuthed { Task { await vm.refresh() } }
        }
        .navigationDestination(item: $detailEntry) { entry in
            LeaderboardDetailView(entry: entry)
        }
    }

    @ViewBuilder
    private var statusBanner: some View {
        if vm.usesMockData, let message = vm.errorMessage {
            HStack(spacing: 8) {
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 14, weight: .semibold))
                Text("Offline preview — \(message)")
                    .font(.bodySmall)
                    .lineLimit(2)
            }
            .foregroundColor(.mutedForeground)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                    .fill(Color.surfaceLight)
            )
        } else if let message = vm.errorMessage, vm.entries.isEmpty {
            Text(message)
                .font(.bodySmall)
                .foregroundColor(.mutedForeground)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
        }
    }

    private var loadingPlaceholder: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Loading leaderboard…")
                .font(.bodySmall)
                .foregroundColor(.mutedForeground)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    private var emptyPlaceholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "trophy")
                .font(.system(size: 32))
                .foregroundColor(.mutedForeground)
            Text(vm.errorMessage ?? "No leaderboard data yet.")
                .font(.bodySmall)
                .foregroundColor(.mutedForeground)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
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
