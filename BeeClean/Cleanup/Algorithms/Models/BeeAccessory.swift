import SwiftUI

// MARK: - Accessory Category
enum AccessoryCategory: String, CaseIterable, Identifiable, Codable {
    case backgrounds
    case auras
    case wings
    case outfits
    case jackets
    case shoes
    case belts
    case ties
    case chains
    case bracelets
    case watch
    case diamonds
    case sunglasses
    case antennae
    case hats
    case rareEffects

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .backgrounds: return "Backgrounds"
        case .auras:       return "Auras"
        case .wings:       return "Wings"
        case .outfits:     return "Outfits"
        case .jackets:     return "Jackets"
        case .shoes:       return "Shoes"
        case .belts:       return "Belts"
        case .ties:        return "Ties"
        case .chains:      return "Chains"
        case .bracelets:   return "Bracelets"
        case .watch:       return "Watch"
        case .diamonds:    return "Diamonds"
        case .sunglasses:  return "Glasses"
        case .antennae:    return "Antennae"
        case .hats:        return "Hats"
        case .rareEffects: return "Rare FX"
        }
    }

    /// SF Symbol shown as the category tab icon (and as fallback art
    /// for items whose imageset is not yet in the asset catalog).
    var sfSymbol: String {
        switch self {
        case .backgrounds: return "photo.fill"
        case .auras:       return "sparkles"
        case .wings:       return "wind"
        case .outfits:     return "tshirt.fill"
        case .jackets:     return "cloud.fill"
        case .shoes:       return "shoeprints.fill"
        case .belts:       return "rectangle.compress.vertical"
        case .ties:        return "comb.fill"
        case .chains:      return "link.circle.fill"
        case .bracelets:   return "circle.hexagongrid.fill"
        case .watch:       return "applewatch"
        case .diamonds:    return "diamond.fill"
        case .sunglasses:  return "sunglasses.fill"
        case .antennae:    return "antenna.radiowaves.left.and.right"
        case .hats:        return "graduationcap.fill"
        case .rareEffects: return "wand.and.stars"
        }
    }

    var tint: Color {
        switch self {
        case .backgrounds: return .categorySlate
        case .auras:       return .categoryViolet
        case .wings:       return .categoryMint
        case .outfits:     return .categoryHoney
        case .jackets:     return .categoryCocoa
        case .shoes:       return .categoryRose
        case .belts:       return .categoryCocoa
        case .ties:        return .categoryCrimson
        case .chains:      return .categoryAmber
        case .bracelets:   return .categoryViolet
        case .watch:       return .categoryTeal
        case .diamonds:    return .categoryIndigo
        case .sunglasses:  return .categorySky
        case .antennae:    return .categoryAmber
        case .hats:        return .categoryHoney
        case .rareEffects: return .categoryCrimson
        }
    }
}

// MARK: - BeeAccessory
struct BeeAccessory: Identifiable, Codable, Hashable {
    let id: String
    let category: AccessoryCategory
    let displayName: String
    /// Image asset name in `Assets.xcassets/BitePalAccessories/`. Falls
    /// back to the category's SF Symbol when the imageset is missing,
    /// so the catalog renders even before real artwork lands.
    let assetName: String
    let price: Int
    let isPremium: Bool
    let rarity: AssetRarity

    init(
        id: String,
        category: AccessoryCategory,
        displayName: String,
        assetName: String? = nil,
        price: Int,
        isPremium: Bool = false,
        rarity: AssetRarity = .common
    ) {
        self.id = id
        self.category = category
        self.displayName = displayName
        self.assetName = assetName ?? id
        self.price = price
        self.isPremium = isPremium
        self.rarity = rarity
    }
}
