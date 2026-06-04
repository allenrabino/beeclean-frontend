import Foundation

struct LeaderboardRowDTO: Codable, Hashable {
    let userId: String
    let rank: Int
    let displayName: String
    let coins: Int
    let storageFreedGB: Double
    let streak: Int
    let equippedAssetIds: [String]

    enum CodingKeys: String, CodingKey {
        case userId
        case rank
        case displayName
        case coins
        case storageFreedGB
        case streak
        case equippedAssetIds
    }

    init(
        userId: String,
        rank: Int,
        displayName: String,
        coins: Int,
        storageFreedGB: Double,
        streak: Int,
        equippedAssetIds: [String]
    ) {
        self.userId = userId
        self.rank = rank
        self.displayName = displayName
        self.coins = coins
        self.storageFreedGB = storageFreedGB
        self.streak = streak
        self.equippedAssetIds = equippedAssetIds
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        userId = try c.decode(String.self, forKey: .userId)
        rank = try c.decode(Int.self, forKey: .rank)
        displayName = try c.decode(String.self, forKey: .displayName)
        coins = try c.decode(Int.self, forKey: .coins)
        if c.contains(.storageFreedGB), !try c.decodeNil(forKey: .storageFreedGB) {
            if let value = try? c.decode(Double.self, forKey: .storageFreedGB) {
                storageFreedGB = value
            } else if let intValue = try? c.decode(Int.self, forKey: .storageFreedGB) {
                storageFreedGB = Double(intValue)
            } else {
                storageFreedGB = 0
            }
        } else {
            storageFreedGB = 0
        }
        streak = try c.decodeIfPresent(Int.self, forKey: .streak) ?? 0
        equippedAssetIds = try c.decodeIfPresent([String].self, forKey: .equippedAssetIds) ?? []
    }
}

struct LeaderboardSelfDTO: Codable, Hashable {
    let entry: LeaderboardRowDTO?
    let inTop100: Bool
    let coinsToNextRank: Int?
    let progressToNextRank: Double
    let coinsToTop100: Int?
    let totalRankedUsers: Int

    enum CodingKeys: String, CodingKey {
        case entry
        case inTop100
        case coinsToNextRank
        case progressToNextRank
        case coinsToTop100
        case totalRankedUsers
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        entry = try c.decodeIfPresent(LeaderboardRowDTO.self, forKey: .entry)
        inTop100 = try c.decodeIfPresent(Bool.self, forKey: .inTop100) ?? (entry != nil)
        coinsToNextRank = try c.decodeIfPresent(Int.self, forKey: .coinsToNextRank)
        progressToNextRank = try c.decodeIfPresent(Double.self, forKey: .progressToNextRank) ?? 0
        coinsToTop100 = try c.decodeIfPresent(Int.self, forKey: .coinsToTop100)
        totalRankedUsers = try c.decodeIfPresent(Int.self, forKey: .totalRankedUsers) ?? 0
    }
}

struct LeaderboardResponseDTO: Codable {
    let top100: [LeaderboardRowDTO]
    let selfInfo: LeaderboardSelfDTO

    enum CodingKeys: String, CodingKey {
        case top100
        case selfInfo = "self"
    }
}

@MainActor
final class LeaderboardService {
    static let shared = LeaderboardService()
    private let auth = AuthService.shared

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    private init() {}

    func fetchLeaderboard() async throws -> LeaderboardResponseDTO {
        let data = try await auth.authenticatedRequest(to: "/leaderboard")
        return try Self.decoder.decode(LeaderboardResponseDTO.self, from: data)
    }
}
