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

    /// SF Symbol for fallback item art in grids and inventory.
    var sfSymbol: String { shopSymbol }

    /// Distinct icon for the shop category strip (polished, recognizable).
    var shopSymbol: String {
        switch self {
        case .backgrounds: return "photo.on.rectangle.angled"
        case .auras:       return "sparkle"
        case .wings:       return "bird.fill"
        case .outfits:     return "backpack.fill"
        case .jackets:     return "shield.lefthalf.filled"
        case .shoes:       return "figure.walk"
        case .belts:       return "lasso"
        case .ties:        return "suit.spade.fill"
        case .chains:      return "link"
        case .bracelets:   return "circlebadge.2.fill"
        case .watch:       return "applewatch"
        case .diamonds:    return "diamond.fill"
        case .sunglasses:  return "sunglasses.fill"
        case .antennae:    return "dot.radiowaves.left.and.right"
        case .hats:        return "crown.fill"
        case .rareEffects: return "wand.and.stars.inverse"
        }
    }

    /// Short label used when generating catalog placeholder names.
    var shopItemSuffix: String {
        switch self {
        case .backgrounds: return "Scene"
        case .auras:       return "Aura"
        case .wings:       return "Wings"
        case .outfits:     return "Fit"
        case .jackets:     return "Cape"
        case .shoes:       return "Kicks"
        case .belts:       return "Belt"
        case .ties:        return "Tie"
        case .chains:      return "Chain"
        case .bracelets:   return "Cuff"
        case .watch:       return "Watch"
        case .diamonds:    return "Gem"
        case .sunglasses:  return "Shades"
        case .antennae:    return "Antenna"
        case .hats:        return "Cap"
        case .rareEffects: return "FX"
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
