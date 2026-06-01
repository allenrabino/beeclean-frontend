import Foundation

// MARK: - Leaderboard Entry
//
// Single rung on the global leaderboard ladder. Coins is the ranking
// metric (single source of truth, no toggle). Storage freed rides
// alongside as the honest flex — visible but not what reorders rows.
struct LeaderboardEntry: Identifiable, Hashable {
    let id: String
    let rank: Int
    let displayName: String
    let coins: Int
    let storageFreedGB: Double
    let streak: Int
    let equippedAccessoryIds: [String]
    let isSelf: Bool
    var inTop100: Bool { rank > 0 && rank <= 100 }
    var coinsToNextRank: Int?
    var progressToNextRank: Double
    var coinsToTop100: Int?

    init(
        id: String,
        rank: Int,
        displayName: String,
        coins: Int,
        storageFreedGB: Double,
        streak: Int,
        equippedAccessoryIds: [String],
        isSelf: Bool,
        coinsToNextRank: Int? = nil,
        progressToNextRank: Double = 0,
        coinsToTop100: Int? = nil
    ) {
        self.id = id
        self.rank = rank
        self.displayName = displayName
        self.coins = coins
        self.storageFreedGB = storageFreedGB
        self.streak = streak
        self.equippedAccessoryIds = equippedAccessoryIds
        self.isSelf = isSelf
        self.coinsToNextRank = coinsToNextRank
        self.progressToNextRank = progressToNextRank
        self.coinsToTop100 = coinsToTop100
    }
}
