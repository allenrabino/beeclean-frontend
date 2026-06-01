import Foundation

struct LeaderboardRowDTO: Codable, Hashable {
    let userId: String
    let rank: Int
    let displayName: String
    let coins: Int
    let storageFreedGB: Double
    let streak: Int
    let equippedAssetIds: [String]
}

struct LeaderboardSelfDTO: Codable, Hashable {
    let entry: LeaderboardRowDTO?
    let inTop100: Bool
    let coinsToNextRank: Int?
    let progressToNextRank: Double
    let coinsToTop100: Int?
    let totalRankedUsers: Int
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

    private init() {}

    func fetchLeaderboard() async throws -> LeaderboardResponseDTO {
        let data = try await auth.authenticatedRequest(to: "/leaderboard")
        return try JSONDecoder().decode(LeaderboardResponseDTO.self, from: data)
    }
}
