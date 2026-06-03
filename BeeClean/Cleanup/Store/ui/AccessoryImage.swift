import SwiftUI

// MARK: - Accessory Image
//
// Renders an accessory's artwork. Tries the named imageset in
// `Assets.xcassets/BitePalAccessories/` first; if it's missing (which
// is the default state until artwork lands), falls back to the
// accessory's category SF Symbol on a tinted preview plate.

struct AccessoryImage: View {
    let accessory: BeeAccessory
    var size: CGFloat = 64
    var style: Style = .standard

    enum Style {
        case standard
        case shopPreview
    }

    var body: some View {
        Group {
            if let ui = UIImage(named: accessory.assetName) {
                Image(uiImage: ui)
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .scaledToFit()
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
    }

    private var placeholder: some View {
        ZStack {
            if style == .shopPreview {
                RoundedRectangle(cornerRadius: size * 0.18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                accessory.category.tint.opacity(0.18),
                                accessory.category.tint.opacity(0.06)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: size * 0.18, style: .continuous)
                            .strokeBorder(accessory.category.tint.opacity(0.22), lineWidth: 0.5)
                    )
            }

            Image(systemName: style == .shopPreview ? accessory.category.shopSymbol : accessory.category.sfSymbol)
                .font(.system(size: size * (style == .shopPreview ? 0.38 : 0.34), weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [accessory.category.tint, accessory.category.tint.opacity(0.72)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(size * 0.16)
        }
    }
}
