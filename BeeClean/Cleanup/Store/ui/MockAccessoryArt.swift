import SwiftUI

// MARK: - Mock Accessory Art
//
// Stand-in artwork for every BeeAccessory until real PNGs land in
// Assets.xcassets/BitePalAccessories/. Each item gets a unique
// gradient background + emoji glyph so the BitePal grid reads as
// 12 colorful illustrated tiles (mirroring the reference shop).
struct MockAccessoryArt: View {
    let accessory: BeeAccessory

    var body: some View {
        ZStack {
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Text(emoji)
                .font(.system(size: 44))
        }
    }

    private var emoji: String {
        switch accessory.id {
        // Hats
        case "hat_baseball_blue": return "🧢"
        case "hat_top":           return "🎩"
        case "hat_crown":         return "👑"
        case "hat_beanie":        return "🧶"
        // Sunglasses
        case "glasses_aviator":   return "🕶️"
        case "glasses_wayfarer":  return "😎"
        case "glasses_round":     return "👓"
        case "glasses_visor":     return "🥽"
        // Ties
        case "tie_classic":       return "👔"
        case "tie_bowtie":        return "🎀"
        case "tie_skinny":        return "🪢"
        case "tie_silk":          return "🧣"
        // Bracelets
        case "bracelet_gold":     return "💛"
        case "bracelet_charm":    return "🔗"
        case "bracelet_beads":    return "📿"
        case "bracelet_diamond":  return "💎"
        // Belts
        case "belt_leather":      return "🟫"
        case "belt_chain":        return "⛓️"
        case "belt_designer":     return "🏷️"
        case "belt_woven":        return "🪢"
        // Wings
        case "wings_silver":      return "🪽"
        case "wings_gold":        return "👼"
        case "wings_neon":        return "✨"
        case "wings_crystal":     return "💠"
        // Watch
        case "watch_classic":     return "⌚️"
        case "watch_smart":       return "📱"
        case "watch_diamond":     return "💍"
        // Diamonds
        case "diamond_stud":      return "💎"
        case "diamond_necklace":  return "📿"
        case "diamond_grill":     return "🦷"
        // Antennae
        case "antennae_classic":  return "📡"
        case "antennae_curly":    return "🌀"
        case "antennae_neon":     return "⚡️"
        case "antennae_crown":    return "👑"
        // Shoes
        case "shoes_sneakers":    return "👟"
        case "shoes_loafers":     return "🥿"
        case "shoes_boots":       return "🥾"
        case "shoes_jordans":     return "👞"
        // Backgrounds
        case "bg_meadow":         return "🌿"
        case "bg_sunset":         return "🌅"
        case "bg_galaxy":         return "🌌"
        case "bg_beach":          return "🏖️"
        default:                  return "✨"
        }
    }

    /// Stable per-id pastel gradient so the same item always looks the
    /// same across launches. Hashing the id keeps colors distributed
    /// across the catalog without a hand-maintained table.
    private var gradientColors: [Color] {
        let palettes: [[Color]] = [
            [Color(hex: "FFD6E0"), Color(hex: "FF8FA3")], // pink
            [Color(hex: "C7F0DB"), Color(hex: "5BC79A")], // mint
            [Color(hex: "FFE4B5"), Color(hex: "FFB347")], // peach
            [Color(hex: "D4E6FF"), Color(hex: "6FA8FF")], // sky
            [Color(hex: "F0D9FF"), Color(hex: "B388FF")], // lavender
            [Color(hex: "FFF3B0"), Color(hex: "FFD449")], // honey
            [Color(hex: "FFD6CC"), Color(hex: "FF7A59")], // coral
            [Color(hex: "CCEFEA"), Color(hex: "4EC8B6")], // teal
            [Color(hex: "EADFFB"), Color(hex: "9D7CE3")], // violet
            [Color(hex: "FFE0EC"), Color(hex: "FF5C8A")], // rose
            [Color(hex: "D9F2D9"), Color(hex: "6EBE6E")], // green
            [Color(hex: "FFE9C7"), Color(hex: "FFA94D")], // amber
        ]
        // `abs(Int.min)` traps; mask the sign bit instead so any hashValue
        // (including the rare Int.min Swift can return) maps cleanly into
        // the palette range.
        let idx = (accessory.id.hashValue & Int.max) % palettes.count
        return palettes[idx]
    }
}
