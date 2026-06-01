import Foundation

struct AvatarStateDTO: Codable {
    let beeDisplayName: String?
    let ownedAssetIds: [String]
    let equippedBySlot: [String: String]
    let shopBonusCoins: Int
    let updatedAt: String?
}

struct AvatarSyncRequest: Codable {
    let beeDisplayName: String?
    let ownedAssetIds: [String]
    let equippedBySlot: [String: String]
    let shopBonusCoins: Int
}

@MainActor
final class AvatarInventoryService {
    static let shared = AvatarInventoryService()
    private let auth = AuthService.shared

    private init() {}

    func fetchRemoteState() async throws -> AvatarStateDTO {
        let data = try await auth.authenticatedRequest(to: "/avatar")
        return try JSONDecoder().decode(AvatarStateDTO.self, from: data)
    }

    @discardableResult
    func syncLocalState(
        beeDisplayName: String?,
        inventory: UserInventory,
        shopBonusCoins: Int
    ) async throws -> AvatarStateDTO {
        let body = try JSONEncoder().encode(
            AvatarSyncRequest(
                beeDisplayName: beeDisplayName,
                ownedAssetIds: Array(inventory.ownedAssetIds).sorted(),
                equippedBySlot: inventory.equipped.bySlot,
                shopBonusCoins: shopBonusCoins
            )
        )
        let data = try await auth.authenticatedRequest(to: "/avatar", method: "PUT", body: body)
        return try JSONDecoder().decode(AvatarStateDTO.self, from: data)
    }
}
