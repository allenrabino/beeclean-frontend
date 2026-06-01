import SwiftUI

struct BeeAvatarView: View {
    let equippedAssetIds: [String]
    var size: CGFloat = 200
    var showsBaseBee: Bool = true

    /// Position configs are authored for the default hero size; scale offsets
    /// so accessories stay on the bee at thumbnail sizes (leaderboard rows, etc.).
    private static let referenceSize: CGFloat = 200
    private var layoutScale: CGFloat { size / Self.referenceSize }

    private var layers: [(id: String, config: AssetPositionConfig)] {
        BeeAssetRegistry.renderLayers(for: equippedAssetIds)
    }

    private var baseZIndex: Int { 50 }

    var body: some View {
        ZStack {
            ForEach(layers.filter { $0.config.zIndex < baseZIndex }, id: \.id) { layer in
                layerView(layer)
            }

            if showsBaseBee {
                Image("BeeHero")
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .zIndex(Double(baseZIndex))
            }

            ForEach(layers.filter { $0.config.zIndex >= baseZIndex }, id: \.id) { layer in
                layerView(layer)
            }
        }
        .frame(width: size * 1.15, height: size * 1.15)
        .clipped()
    }

    @ViewBuilder
    private func layerView(_ layer: (id: String, config: AssetPositionConfig)) -> some View {
        if let accessory = BeeAccessoryCatalog.item(id: layer.id) {
            let layerSize = size * 0.3 * layer.config.scale
            let scaledOffset = CGSize(
                width: layer.config.offset.width * layoutScale,
                height: layer.config.offset.height * layoutScale
            )
            AccessoryImage(accessory: accessory, size: layerSize)
                .offset(scaledOffset)
                .rotationEffect(.degrees(layer.config.rotation))
                .zIndex(Double(layer.config.zIndex))
        }
    }
}

#Preview {
    BeeAvatarView(
        equippedAssetIds: ["hat_royal_honey_crown", "chain_diamond_pollen", "wings_crystal_nectar"],
        size: 180
    )
    .padding()
    .background(Color(hex: "FFE066"))
}
