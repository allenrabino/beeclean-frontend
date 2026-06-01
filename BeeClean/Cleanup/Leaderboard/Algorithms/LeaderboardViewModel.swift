import Foundation
import SwiftUI

@MainActor
final class LeaderboardViewModel: ObservableObject {
    static let shared = LeaderboardViewModel()

    @Published private(set) var entries: [LeaderboardEntry] = []
    @Published private(set) var selfEntry: LeaderboardEntry?
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var usesMockData: Bool = true

    private init() {
        refreshLocal()
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }

        if AuthService.shared.isAuthenticated {
            do {
                let response = try await LeaderboardService.shared.fetchLeaderboard()
                apply(response)
                usesMockData = false
                return
            } catch {
                print("[LeaderboardVM] API fallback to local mock: \(error)")
            }
        }

        try? await Task.sleep(nanoseconds: 150_000_000)
        refreshLocal()
        usesMockData = true
    }

    private func apply(_ response: LeaderboardResponseDTO) {
        entries = response.top100.map { mapRow($0, isSelf: false) }

        if let selfRow = response.selfInfo.entry {
            let mapped = mapRow(
                selfRow,
                isSelf: true,
                coinsToNextRank: response.selfInfo.coinsToNextRank,
                progressToNextRank: response.selfInfo.progressToNextRank,
                coinsToTop100: response.selfInfo.coinsToTop100
            )
            selfEntry = mapped

            if !response.selfInfo.inTop100 {
                // Keep Top 100 clean; self row shown via RelativeRankCard / sticky footer.
            } else if !entries.contains(where: { $0.id == mapped.id }) {
                var merged = entries
                merged.append(mapped)
                merged.sort { $0.coins > $1.coins }
                entries = merged.enumerated().map { index, entry in
                    LeaderboardEntry(
                        id: entry.id,
                        rank: index + 1,
                        displayName: entry.displayName,
                        coins: entry.coins,
                        storageFreedGB: entry.storageFreedGB,
                        streak: entry.streak,
                        equippedAccessoryIds: entry.equippedAccessoryIds,
                        isSelf: entry.isSelf,
                        coinsToNextRank: entry.coinsToNextRank,
                        progressToNextRank: entry.progressToNextRank,
                        coinsToTop100: entry.coinsToTop100
                    )
                }
            }
        } else {
            refreshLocalSelfOnly(response.selfInfo)
        }
    }

    private func mapRow(
        _ row: LeaderboardRowDTO,
        isSelf: Bool,
        coinsToNextRank: Int? = nil,
        progressToNextRank: Double = 0,
        coinsToTop100: Int? = nil
    ) -> LeaderboardEntry {
        LeaderboardEntry(
            id: row.userId,
            rank: row.rank,
            displayName: row.displayName,
            coins: row.coins,
            storageFreedGB: row.storageFreedGB,
            streak: row.streak,
            equippedAccessoryIds: row.equippedAssetIds,
            isSelf: isSelf,
            coinsToNextRank: coinsToNextRank,
            progressToNextRank: progressToNextRank,
            coinsToTop100: coinsToTop100
        )
    }

    private func refreshLocalSelfOnly(_ selfInfo: LeaderboardSelfDTO) {
        refreshLocal()
        if var me = selfEntry {
            me = LeaderboardEntry(
                id: me.id,
                rank: me.rank,
                displayName: me.displayName,
                coins: me.coins,
                storageFreedGB: me.storageFreedGB,
                streak: me.streak,
                equippedAccessoryIds: me.equippedAccessoryIds,
                isSelf: true,
                coinsToNextRank: selfInfo.coinsToNextRank,
                progressToNextRank: selfInfo.progressToNextRank,
                coinsToTop100: selfInfo.coinsToTop100
            )
            selfEntry = me
        }
    }

    private func refreshLocal() {
        let stats = HiveStatsManager.shared
        let selfCoins = stats.coinsBalance
        let selfGB = Double(stats.lifetimeBytesSaved) / 1_000_000_000.0
        let selfStreak = stats.currentStreak
        let selfEquipped = Array(BitePalViewModel.shared.equippedByCategory.values)

        let mocked = Self.mockTop()
        var combined = mocked
        let selfAccessories: [String] = selfEquipped.isEmpty
            ? ["hat_baseball_blue"]
            : selfEquipped
        let placeholder = LeaderboardEntry(
            id: "self",
            rank: 0,
            displayName: "You",
            coins: selfCoins,
            storageFreedGB: selfGB,
            streak: selfStreak,
            equippedAccessoryIds: selfAccessories,
            isSelf: true
        )
        combined.append(placeholder)
        combined.sort { $0.coins > $1.coins }

        var ranked: [LeaderboardEntry] = []
        ranked.reserveCapacity(combined.count)
        for (i, e) in combined.enumerated() {
            ranked.append(
                LeaderboardEntry(
                    id: e.id,
                    rank: i + 1,
                    displayName: e.displayName,
                    coins: e.coins,
                    storageFreedGB: e.storageFreedGB,
                    streak: e.streak,
                    equippedAccessoryIds: e.equippedAccessoryIds,
                    isSelf: e.isSelf
                )
            )
        }
        let top100Cutoff = ranked.first { $0.rank == 100 }?.coins ?? 0
        ranked = ranked.map { entry in
            var copy = entry
            if entry.isSelf && entry.rank > 100 {
                copy = LeaderboardEntry(
                    id: entry.id,
                    rank: entry.rank,
                    displayName: entry.displayName,
                    coins: entry.coins,
                    storageFreedGB: entry.storageFreedGB,
                    streak: entry.streak,
                    equippedAccessoryIds: entry.equippedAccessoryIds,
                    isSelf: entry.isSelf,
                    coinsToTop100: max(0, top100Cutoff - entry.coins + 1)
                )
            }
            return copy
        }
        entries = ranked.filter { $0.rank <= 100 }
        selfEntry = ranked.first { $0.isSelf }
    }

    private static let mockNames: [String] = [
        "QueenBeeAlpha", "HoneyHive7", "BuzzMaster", "GoldenWing", "Stinger99",
        "BeeWell", "Honeycombo", "HiveQueen", "WaxWizard", "NectarKing",
        "PollenPete", "RoyalJelly", "DroneDave", "FlightOps", "ZephyrZ",
        "MeadowMia", "AmberAce", "SunSeekerX", "DandelionDuke", "ClovrChris",
        "BuzzCutBea", "HiveHopper", "BeeRescue", "SwarmCipher", "GoldDust",
        "WaxLyrical", "Foragelink", "HoneyWraps", "QueenComb", "BeeKnight",
        "ApiaryAna", "JellyJam", "CrystalWax", "NectarNinja", "BumbleBri",
        "RoseHoneyx", "ShadowHive", "BeesNeck", "GoldComb", "VioletVespa",
        "DustyDrone", "SugarSwarm", "PollenPilot", "BeeBard", "GildedFlight",
        "MorningBuzz", "LunarHive", "EclipseBee", "WildflowerW", "FrostNectar",
        "OakHoney", "FernFlight", "WillowWax", "BasilBee", "MarigoldM",
        "SagebrushS", "ThistleT", "IvyHive", "CedarComb", "BirchBee",
        "MapleMist", "PinePollen", "AshenAce", "RowanRoyal", "ElderEm",
        "HazelHive", "JuneberryJ", "RedwoodR", "SequoiaS", "BalsamB",
        "CypressC", "TamarackT", "JuniperJ", "AspenA", "AldreyA",
        "LarchL", "TupeloT", "MyrtleM", "OrchidO", "PetalP",
        "BloomB", "FernyF", "GlowG", "HoneyH", "InkwellI",
        "JadeJ", "KineticK", "LumenL", "MarrowM", "NovaN",
        "OracleO", "PrismP", "QuartzQ", "RiverR", "SolaceS",
        "TempestT", "UmbralU", "VividV", "WhisperW", "XenithX"
    ]

    private static func mockTop() -> [LeaderboardEntry] {
        let accessoryPool: [[String]] = [
            ["hat_royal_honey_crown", "chain_diamond_pollen", "wings_crystal_nectar"],
            ["hat_crown", "glasses_midnight_hive", "jacket_black_gold_cape"],
            ["wings_crystal", "diamond_necklace", "shoes_jordans"],
            ["hat_baseball_blue", "glasses_wayfarer", "aura_rare_nectar"],
            ["antennae_neon", "wings_neon", "watch_smart"],
            ["outfit_golden_hive", "tie_classic", "belt_leather"],
            ["bracelet_diamond", "fx_golden_spark"],
            ["glasses_chrome_honey", "tie_bowtie"],
            ["antennae_curly", "shoes_loafers"],
            ["antennae_classic"]
        ]

        return (0..<100).map { i in
            let baseCoins = 9800 - (i * 90) + Int.random(in: -25...25, using: &Self.seededRng)
            let coins = max(50, baseCoins)
            let gb = Double(coins) / 110.0 + Double.random(in: -0.5...1.5, using: &Self.seededRng)
            let streak = max(1, 60 - i / 2 + Int.random(in: -3...3, using: &Self.seededRng))
            let name = mockNames[i % mockNames.count]
            let acc = accessoryPool[i % accessoryPool.count]
            return LeaderboardEntry(
                id: "mock_\(i)",
                rank: i + 1,
                displayName: name,
                coins: coins,
                storageFreedGB: max(0.2, gb),
                streak: streak,
                equippedAccessoryIds: acc,
                isSelf: false
            )
        }
    }

    nonisolated(unsafe) private static var seededRng = SeededRandom(seed: 0xBEE_C1EA_47)
}

// MARK: - Seeded RNG

struct SeededRandom: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { self.state = seed == 0 ? 0xDEAD_BEEF_CAFE_FACE : seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
