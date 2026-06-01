import SwiftUI

// MARK: - BitePal Accessory Card
//
// Single grid cell in the BitePal shop. Tap the artwork to preview on
// the bee; use the button to Buy / Equip / Unequip.

struct BitePalAccessoryCard: View {
    let accessory: BeeAccessory
    @ObservedObject var vm: BitePalViewModel = .shared
    @ObservedObject var stats: HiveStatsManager = .shared

    @State private var deniedFlash: Bool = false

    private var isPreviewing: Bool { vm.isPreviewing(accessory) }

    var body: some View {
        VStack(spacing: 8) {
            artwork
            Text(accessory.displayName)
                .font(.labelMedium)
                .foregroundColor(.foreground)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            actionButton
        }
        .padding(8)
    }

    private var artwork: some View {
        Button {
            HapticManager.shared.buttonTap()
            if isPreviewing {
                vm.clearPreview()
            } else {
                vm.preview(accessory)
            }
        } label: {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                .fill(Color.surfaceLight)
                .frame(height: 100)
                .overlay(
                    AccessoryImage(accessory: accessory, size: 72, style: .shopPreview)
                )
                .overlay(alignment: .topTrailing) {
                    if accessory.isPremium {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Circle().fill(Color.accentColor))
                            .padding(8)
                    }
                }
                .overlay(alignment: .bottomLeading) {
                    if isPreviewing {
                        Label("Preview", systemImage: "eye.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.accentColor))
                            .padding(8)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                        .strokeBorder(borderColor, lineWidth: borderWidth)
                )
        }
        .buttonStyle(.plain)
    }

    private var borderColor: Color {
        if isPreviewing { return Color.accentColor }
        if vm.isEquipped(accessory) { return Color.accentColor.opacity(0.85) }
        return Color.border
    }

    private var borderWidth: CGFloat {
        isPreviewing || vm.isEquipped(accessory) ? 2 : 0.5
    }

    private var actionButton: some View {
        Button(action: tap) {
            HStack(spacing: 4) {
                if vm.isEquipped(accessory) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Equipped")
                } else if vm.isOwned(accessory) {
                    Text("Equip")
                } else {
                    Image(systemName: "bitcoinsign.circle.fill")
                        .foregroundColor(.white)
                    Text("\(accessory.price)")
                }
            }
            .font(.labelSmall)
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(buttonColor))
        }
        .buttonStyle(.plain)
        .scaleEffect(deniedFlash ? 1.08 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.5), value: deniedFlash)
    }

    private var buttonColor: Color {
        if vm.isEquipped(accessory) { return .success }
        if vm.isOwned(accessory) { return .accentColor }
        return stats.coinsBalance >= accessory.price ? .primaryColor : .mutedForeground
    }

    private func tap() {
        if vm.isEquipped(accessory) {
            vm.unequip(category: accessory.category)
            vm.clearPreview()
        } else if vm.isOwned(accessory) {
            vm.equip(accessory)
            vm.preview(accessory)
        } else if vm.buy(accessory) {
            vm.preview(accessory)
        } else {
            deniedFlash = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                deniedFlash = false
            }
        }
    }
}
