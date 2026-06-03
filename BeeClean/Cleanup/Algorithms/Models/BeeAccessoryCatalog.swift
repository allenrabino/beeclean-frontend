import Foundation

// MARK: - BeeAccessory Catalog
//
// Seed catalog used by BitePalView while real artwork is in production.
// Each accessory falls back to its category's SF Symbol if no imageset
// is present in `Assets.xcassets/BitePalAccessories/`, so dropping in
// PNGs later is a zero-code change.
enum BeeAccessoryCatalog {
    static let all: [BeeAccessory] = {
        var items: [BeeAccessory] = []

        // ── Hats ──────────────────────────────────────────────
        items += [
            .init(id: "hat_baseball_blue", category: .hats, displayName: "Baseball Cap", price: 120),
            .init(id: "hat_top",           category: .hats, displayName: "Top Hat",      price: 280),
            .init(id: "hat_crown",         category: .hats, displayName: "Queen Crown",  price: 750, isPremium: true),
            .init(id: "hat_beanie",        category: .hats, displayName: "Beanie",       price: 90),
        ]

        // ── Sunglasses ────────────────────────────────────────
        items += [
            .init(id: "glasses_aviator",   category: .sunglasses, displayName: "Aviators",     price: 150),
            .init(id: "glasses_wayfarer",  category: .sunglasses, displayName: "Wayfarers",    price: 180),
            .init(id: "glasses_round",     category: .sunglasses, displayName: "Round Shades", price: 110),
            .init(id: "glasses_visor",     category: .sunglasses, displayName: "Cyber Visor",  price: 420, isPremium: true),
        ]

        // ── Ties ──────────────────────────────────────────────
        items += [
            .init(id: "tie_classic",  category: .ties, displayName: "Classic Tie", price: 80),
            .init(id: "tie_bowtie",   category: .ties, displayName: "Bowtie",      price: 100),
            .init(id: "tie_skinny",   category: .ties, displayName: "Skinny Tie",  price: 90),
            .init(id: "tie_silk",     category: .ties, displayName: "Silk Tie",    price: 220, isPremium: true),
        ]

        // ── Bracelets ─────────────────────────────────────────
        items += [
            .init(id: "bracelet_gold",   category: .bracelets, displayName: "Gold Cuff",    price: 220),
            .init(id: "bracelet_charm",  category: .bracelets, displayName: "Charm Wrap",   price: 160),
            .init(id: "bracelet_beads",  category: .bracelets, displayName: "Bead Stack",   price: 120),
            .init(id: "bracelet_diamond", category: .bracelets, displayName: "Diamond Cuff", price: 600, isPremium: true),
        ]

        // ── Belts ─────────────────────────────────────────────
        items += [
            .init(id: "belt_leather",  category: .belts, displayName: "Leather Belt", price: 90),
            .init(id: "belt_chain",    category: .belts, displayName: "Chain Belt",   price: 180),
            .init(id: "belt_designer", category: .belts, displayName: "Designer",     price: 450, isPremium: true),
            .init(id: "belt_woven",    category: .belts, displayName: "Woven Belt",   price: 100),
        ]

        // ── Wings ─────────────────────────────────────────────
        items += [
            .init(id: "wings_silver",   category: .wings, displayName: "Silver Wings", price: 300),
            .init(id: "wings_gold",     category: .wings, displayName: "Gold Wings",   price: 500, isPremium: true),
            .init(id: "wings_neon",     category: .wings, displayName: "Neon Wings",   price: 400),
            .init(id: "wings_crystal",  category: .wings, displayName: "Crystal",      price: 800, isPremium: true),
        ]

        // ── Watch ─────────────────────────────────────────────
        items += [
            .init(id: "watch_classic",  category: .watch, displayName: "Classic",   price: 160),
            .init(id: "watch_smart",    category: .watch, displayName: "Smart",     price: 240),
            .init(id: "watch_diamond",  category: .watch, displayName: "Diamond",   price: 720, isPremium: true),
        ]

        // ── Diamonds ──────────────────────────────────────────
        items += [
            .init(id: "diamond_stud",    category: .diamonds, displayName: "Studs",      price: 220),
            .init(id: "diamond_necklace", category: .diamonds, displayName: "Necklace",  price: 540),
            .init(id: "diamond_grill",   category: .diamonds, displayName: "Diamond Grill", price: 900, isPremium: true),
        ]

        // ── Antennae ──────────────────────────────────────────
        items += [
            .init(id: "antennae_classic", category: .antennae, displayName: "Classic",    price: 60),
            .init(id: "antennae_curly",   category: .antennae, displayName: "Curly",      price: 90),
            .init(id: "antennae_neon",    category: .antennae, displayName: "Neon Pop",   price: 180),
            .init(id: "antennae_crown",   category: .antennae, displayName: "Crown Tips", price: 320, isPremium: true),
        ]

        // ── Shoes ─────────────────────────────────────────────
        items += [
            .init(id: "shoes_sneakers", category: .shoes, displayName: "Sneakers", price: 110),
            .init(id: "shoes_loafers",  category: .shoes, displayName: "Loafers",  price: 140),
            .init(id: "shoes_boots",    category: .shoes, displayName: "Boots",    price: 180),
            .init(id: "shoes_jordans",  category: .shoes, displayName: "Jordans",  price: 480, isPremium: true),
        ]

        // ── Backgrounds ───────────────────────────────────────
        items += [
            .init(id: "bg_meadow",   category: .backgrounds, displayName: "Meadow",   price: 200),
            .init(id: "bg_sunset",   category: .backgrounds, displayName: "Sunset",   price: 250),
            .init(id: "bg_galaxy",   category: .backgrounds, displayName: "Galaxy",   price: 450, isPremium: true),
            .init(id: "bg_beach",    category: .backgrounds, displayName: "Beach",    price: 280),
        ]

        // ── Premium collectible examples ──────────────────────
        items += [
            .init(id: "hat_royal_honey_crown", category: .hats, displayName: "Royal Honey Crown", price: 1200, isPremium: true, rarity: .legendary),
            .init(id: "chain_diamond_pollen", category: .chains, displayName: "Diamond Pollen Chain", price: 980, isPremium: true, rarity: .legendary),
            .init(id: "glasses_midnight_hive", category: .sunglasses, displayName: "Midnight Hive Shades", price: 640, isPremium: true, rarity: .epic),
            .init(id: "wings_crystal_nectar", category: .wings, displayName: "Crystal Nectar Wings", price: 1100, isPremium: true, rarity: .legendary),
            .init(id: "outfit_golden_hive", category: .outfits, displayName: "Golden Hive Backpack", price: 720, isPremium: true, rarity: .epic),
            .init(id: "aura_rare_nectar", category: .auras, displayName: "Rare Nectar Aura", price: 860, isPremium: true, rarity: .legendary),
            .init(id: "jacket_black_gold_cape", category: .jackets, displayName: "Black & Gold Hive Cape", price: 940, isPremium: true, rarity: .legendary),
            .init(id: "glasses_chrome_honey", category: .sunglasses, displayName: "Chrome Honey Goggles", price: 580, isPremium: true, rarity: .epic),
            .init(id: "fx_golden_spark", category: .rareEffects, displayName: "Golden Spark FX", price: 1500, isPremium: true, rarity: .oneOfOne),
        ]

        return items
    }()

    /// Target grid size per category (shop scroll is tuned for this count).
    static let targetCountPerCategory = 25

    static func items(in category: AccessoryCategory) -> [BeeAccessory] {
        let defined = all.filter { $0.category == category }
        guard defined.count < targetCountPerCategory else {
            return Array(defined.prefix(targetCountPerCategory))
        }
        return defined + placeholderItems(
            category: category,
            startIndex: defined.count,
            count: targetCountPerCategory - defined.count
        )
    }

    private static let variantPrefixes = [
        "Dawn", "Dusk", "Glow", "Pulse", "Prism", "Shine", "Royal", "Neon",
        "Honey", "Buzz", "Hive", "Golden", "Crystal", "Velvet", "Silk",
        "Chrome", "Aurora", "Midnight", "Solar", "Lunar", "Stinger", "Nectar",
        "Pollen", "Meadow", "Citrus"
    ]

    private static func placeholderItems(
        category: AccessoryCategory,
        startIndex: Int,
        count: Int
    ) -> [BeeAccessory] {
        guard count > 0 else { return [] }
        return (0..<count).map { offset in
            let index = startIndex + offset
            let prefix = variantPrefixes[index % variantPrefixes.count]
            let tier = index / variantPrefixes.count
            let name = tier == 0
                ? "\(prefix) \(category.shopItemSuffix)"
                : "\(prefix) \(category.shopItemSuffix) \(tier + 1)"
            let price = 70 + (index * 18) + (index % 6 == 0 ? 120 : 0)
            let premium = index % 9 == 0
            return BeeAccessory(
                id: "\(category.rawValue)_variant_\(index)",
                category: category,
                displayName: name,
                price: price,
                isPremium: premium,
                rarity: premium ? .epic : .common
            )
        }
    }

    static func item(id: String) -> BeeAccessory? {
        all.first { $0.id == id }
    }
}
