import Foundation
import SwiftUI

// MARK: - Asset Rarity

enum AssetRarity: String, Codable, CaseIterable {
    case common
    case rare
    case epic
    case legendary
    case oneOfOne

    var displayName: String {
        switch self {
        case .common: return "Common"
        case .rare: return "Rare"
        case .epic: return "Epic"
        case .legendary: return "Legendary"
        case .oneOfOne: return "1 of 1"
        }
    }

    var tint: Color {
        switch self {
        case .common: return Color(hex: "9CA3AF")
        case .rare: return Color(hex: "3B82F6")
        case .epic: return Color(hex: "8B5CF6")
        case .legendary: return Color(hex: "F59E0B")
        case .oneOfOne: return Color(hex: "EF4444")
        }
    }
}

// MARK: - Asset Slot (render layer)

/// Each slot maps to one equipped item and a z-order layer on the bee rig.
typealias AssetSlot = AccessoryCategory

// MARK: - Position Config

struct AssetPositionConfig: Codable, Hashable {
    var zIndex: Int
    var xOffset: CGFloat
    var yOffset: CGFloat
    var scale: CGFloat
    var rotation: Double

    init(
        zIndex: Int,
        xOffset: CGFloat = 0,
        yOffset: CGFloat = 0,
        scale: CGFloat = 1,
        rotation: Double = 0
    ) {
        self.zIndex = zIndex
        self.xOffset = xOffset
        self.yOffset = yOffset
        self.scale = scale
        self.rotation = rotation
    }

    var offset: CGSize { CGSize(width: xOffset, height: yOffset) }
}

extension AccessoryCategory {
    /// Default render layer for the bee rig (low → high).
    var defaultZIndex: Int {
        switch self {
        case .backgrounds: return 0
        case .auras:       return 10
        case .wings:       return 20
        case .outfits:     return 30
        case .jackets:     return 35
        case .shoes:       return 40
        case .belts:       return 55
        case .ties, .chains: return 60
        case .bracelets:   return 65
        case .watch:       return 66
        case .diamonds:    return 70
        case .sunglasses:  return 80
        case .antennae:    return 90
        case .hats:        return 100
        case .rareEffects: return 110
        }
    }

    var defaultPosition: AssetPositionConfig {
        switch self {
        case .backgrounds: return .init(zIndex: defaultZIndex, scale: 1.15)
        case .auras:       return .init(zIndex: defaultZIndex, scale: 1.25)
        case .wings:       return .init(zIndex: defaultZIndex, xOffset: -75, scale: 1.05)
        case .outfits:     return .init(zIndex: defaultZIndex, yOffset: 10, scale: 1.02)
        case .jackets:     return .init(zIndex: defaultZIndex, yOffset: 5, scale: 1.03)
        case .shoes:       return .init(zIndex: defaultZIndex, yOffset: 80)
        case .belts:       return .init(zIndex: defaultZIndex, yOffset: 50)
        case .ties:        return .init(zIndex: defaultZIndex, yOffset: 25)
        case .chains:      return .init(zIndex: defaultZIndex, yOffset: 15, scale: 1.05)
        case .bracelets:   return .init(zIndex: defaultZIndex, xOffset: 55, yOffset: 35)
        case .watch:       return .init(zIndex: defaultZIndex, xOffset: -55, yOffset: 35)
        case .diamonds:    return .init(zIndex: defaultZIndex, yOffset: 5)
        case .sunglasses:  return .init(zIndex: defaultZIndex, yOffset: -25)
        case .antennae:    return .init(zIndex: defaultZIndex, yOffset: -95)
        case .hats:        return .init(zIndex: defaultZIndex, yOffset: -80)
        case .rareEffects: return .init(zIndex: defaultZIndex, scale: 1.2)
        }
    }
}

// MARK: - Bee Asset (catalog metadata)

struct BeeAsset: Identifiable, Hashable {
    let id: String
    let name: String
    let slot: AssetSlot
    let rarity: AssetRarity
    let assetName: String
    let price: Int
    let isPremium: Bool
    let position: AssetPositionConfig

    init(
        id: String,
        slot: AssetSlot,
        name: String,
        assetName: String? = nil,
        rarity: AssetRarity = .common,
        price: Int,
        isPremium: Bool = false,
        position: AssetPositionConfig? = nil
    ) {
        self.id = id
        self.slot = slot
        self.name = name
        self.assetName = assetName ?? id
        self.rarity = rarity
        self.price = price
        self.isPremium = isPremium
        self.position = position ?? slot.defaultPosition
    }

    var accessory: BeeAccessory {
        BeeAccessory(
            id: id,
            category: slot,
            displayName: name,
            assetName: assetName,
            price: price,
            isPremium: isPremium,
            rarity: rarity
        )
    }
}

// MARK: - Inventory / Equipped

struct EquippedAssets: Codable, Hashable {
    var bySlot: [String: String]

    init(bySlot: [String: String] = [:]) {
        self.bySlot = bySlot
    }

    var assetIds: [String] { Array(bySlot.values) }

    func assetId(for slot: AssetSlot) -> String? {
        bySlot[slot.rawValue]
    }

    mutating func equip(_ assetId: String, slot: AssetSlot) {
        bySlot[slot.rawValue] = assetId
    }

    mutating func unequip(slot: AssetSlot) {
        bySlot.removeValue(forKey: slot.rawValue)
    }
}

struct UserInventory: Codable, Hashable {
    var ownedAssetIds: Set<String>
    var equipped: EquippedAssets

    init(ownedAssetIds: Set<String> = [], equipped: EquippedAssets = .init()) {
        self.ownedAssetIds = ownedAssetIds
        self.equipped = equipped
    }
}

// MARK: - Asset Registry

enum BeeAssetRegistry {
    static let all: [BeeAsset] = BeeAccessoryCatalog.all.map { accessory in
        BeeAsset(
            id: accessory.id,
            slot: accessory.category,
            name: accessory.displayName,
            assetName: accessory.assetName,
            rarity: accessory.rarity,
            price: accessory.price,
            isPremium: accessory.isPremium,
            position: positionOverride(for: accessory.id) ?? accessory.category.defaultPosition
        )
    }

    static func asset(id: String) -> BeeAsset? {
        all.first { $0.id == id }
    }

    static func assets(in slot: AssetSlot) -> [BeeAsset] {
        all.filter { $0.slot == slot }
    }

    static func position(for assetId: String) -> AssetPositionConfig {
        if let asset = asset(id: assetId) { return asset.position }
        if let accessory = BeeAccessoryCatalog.item(id: assetId) {
            return positionOverride(for: assetId) ?? accessory.category.defaultPosition
        }
        return AssetPositionConfig(zIndex: 50)
    }

    static func renderLayers(for assetIds: [String]) -> [(id: String, config: AssetPositionConfig)] {
        assetIds.compactMap { id -> (String, AssetPositionConfig)? in
            guard BeeAccessoryCatalog.item(id: id) != nil || asset(id: id) != nil else { return nil }
            return (id, position(for: id))
        }
        .sorted { $0.config.zIndex < $1.config.zIndex }
    }

    private static func positionOverride(for assetId: String) -> AssetPositionConfig? {
        switch assetId {
        case "wings_crystal", "wings_crystal_nectar":
            return AssetPositionConfig(zIndex: AssetSlot.wings.defaultZIndex, xOffset: -80, yOffset: -5, scale: 1.1)
        case "hat_crown", "hat_royal_honey_crown":
            return AssetPositionConfig(zIndex: AssetSlot.hats.defaultZIndex, yOffset: -88, scale: 1.08)
        case "glasses_visor", "glasses_chrome_honey":
            return AssetPositionConfig(zIndex: AssetSlot.sunglasses.defaultZIndex, yOffset: -28, scale: 1.05)
        default:
            return nil
        }
    }
}
