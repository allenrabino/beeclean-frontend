import Foundation
import SwiftUI

// MARK: - BitePal View Model
//
// Single source of truth for the user's accessory inventory and the
// currently equipped pieces. Owned/equipped state is persisted via
// @AppStorage JSON blobs so it survives relaunch without a backend.
// Buy/equip/unequip are MainActor — there's no async work — and they
// publish through ObservableObject so SwiftUI redraws react instantly.
@MainActor
final class BitePalViewModel: ObservableObject {
    static let shared = BitePalViewModel()

    @AppStorage("bitepal_ownedAccessoryIdsRaw") private var ownedRaw: String = "[]"
    @AppStorage("bitepal_equippedRaw") private var equippedRaw: String = "{}"

    /// Triggers SwiftUI updates whenever owned/equipped maps change.
    /// @AppStorage already publishes, but we expose the decoded values
    /// through computed properties so consumers don't have to JSON-parse.
    @Published private var bump: Int = 0

    private init() {}

    // MARK: - Reads

    var ownedIds: Set<String> {
        _ = bump
        guard let data = ownedRaw.data(using: .utf8),
              let arr = try? JSONDecoder().decode([String].self, from: data)
        else { return [] }
        return Set(arr)
    }

    /// Maps category raw value → equipped accessory id.
    var equippedByCategory: [String: String] {
        _ = bump
        guard let data = equippedRaw.data(using: .utf8),
              let dict = try? JSONDecoder().decode([String: String].self, from: data)
        else { return [:] }
        return dict
    }

    /// Flat list of accessory ids currently worn — convenient for
    /// rendering preview overlays in one ForEach.
    var equippedIds: [String] {
        Array(equippedByCategory.values)
    }

    /// Non-persisted shop preview — lets the user try an item on the
    /// bee before buying or equipping it.
    @Published private(set) var previewAccessoryId: String? = nil

    /// Equipped ids with the preview item swapped into its slot.
    var displayEquippedIds: [String] {
        guard let previewId = previewAccessoryId,
              let preview = BeeAccessoryCatalog.item(id: previewId)
        else { return equippedIds }

        var ids = equippedIds.filter { id in
            BeeAccessoryCatalog.item(id: id)?.category != preview.category
        }
        ids.append(previewId)
        return ids
    }

    func isPreviewing(_ accessory: BeeAccessory) -> Bool {
        previewAccessoryId == accessory.id
    }

    func preview(_ accessory: BeeAccessory?) {
        previewAccessoryId = accessory?.id
        bump &+= 1
    }

    func clearPreview() {
        guard previewAccessoryId != nil else { return }
        previewAccessoryId = nil
        bump &+= 1
    }

    func isOwned(_ accessory: BeeAccessory) -> Bool {
        ownedIds.contains(accessory.id)
    }

    func isEquipped(_ accessory: BeeAccessory) -> Bool {
        equippedByCategory[accessory.category.rawValue] == accessory.id
    }

    // MARK: - Writes

    /// Attempts to debit `accessory.price` coins from HiveStatsManager
    /// and add the item to the inventory. Returns `false` if the user
    /// can't afford it. On success, auto-equips the item so the user
    /// sees their purchase land on the bee immediately.
    @discardableResult
    func buy(_ accessory: BeeAccessory) -> Bool {
        guard !isOwned(accessory) else { return true }
        guard HiveStatsManager.shared.spendCoins(accessory.price) else { return false }
        var owned = ownedIds
        owned.insert(accessory.id)
        persist(owned: owned)
        equip(accessory)
        return true
    }

    func equip(_ accessory: BeeAccessory) {
        guard isOwned(accessory) else { return }
        var dict = equippedByCategory
        dict[accessory.category.rawValue] = accessory.id
        persist(equipped: dict)
    }

    func unequip(category: AccessoryCategory) {
        var dict = equippedByCategory
        dict.removeValue(forKey: category.rawValue)
        persist(equipped: dict)
    }

    func toggleEquip(_ accessory: BeeAccessory) {
        if isEquipped(accessory) {
            unequip(category: accessory.category)
        } else {
            equip(accessory)
        }
    }

    // MARK: - Persistence

    private func persist(owned: Set<String>) {
        if let data = try? JSONEncoder().encode(Array(owned).sorted()),
           let str = String(data: data, encoding: .utf8) {
            ownedRaw = str
            bump &+= 1
            scheduleSync()
        }
    }

    private func persist(equipped: [String: String]) {
        if let data = try? JSONEncoder().encode(equipped),
           let str = String(data: data, encoding: .utf8) {
            equippedRaw = str
            bump &+= 1
            scheduleSync()
        }
    }

    var inventory: UserInventory {
        UserInventory(
            ownedAssetIds: ownedIds,
            equipped: EquippedAssets(bySlot: equippedByCategory)
        )
    }

    func pullRemoteIfNeeded() async {
        guard AuthService.shared.isAuthenticated else { return }
        do {
            let remote = try await AvatarInventoryService.shared.fetchRemoteState()
            if let data = try? JSONEncoder().encode(remote.ownedAssetIds),
               let ownedStr = String(data: data, encoding: .utf8) {
                ownedRaw = ownedStr
            }
            if let data = try? JSONEncoder().encode(remote.equippedBySlot),
               let equippedStr = String(data: data, encoding: .utf8) {
                equippedRaw = equippedStr
            }
            bump &+= 1
        } catch {
            print("[BitePalVM] remote pull failed: \(error)")
        }
    }

    private func scheduleSync() {
        Task {
            guard AuthService.shared.isAuthenticated else { return }
            do {
                _ = try await AvatarInventoryService.shared.syncLocalState(
                    beeDisplayName: nil,
                    inventory: inventory,
                    shopBonusCoins: HiveStatsManager.shared.bonusCoins
                )
            } catch {
                print("[BitePalVM] sync failed: \(error)")
            }
        }
    }
}
