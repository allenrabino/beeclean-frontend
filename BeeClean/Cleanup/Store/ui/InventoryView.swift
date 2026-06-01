import SwiftUI

// MARK: - Inventory View
//
// Owned-asset browser shell. Equip/unequip uses the same BitePalViewModel
// as the shop; this screen is the "closet" side of the avatar system.

struct InventoryView: View {
    @StateObject private var vm = BitePalViewModel.shared
    @State private var selectedSlot: AssetSlot = .hats

    private var ownedAssets: [BeeAsset] {
        BeeAssetRegistry.all.filter { vm.isOwned($0.accessory) }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                BeeAvatarView(equippedAssetIds: vm.equippedIds, size: 180)
                    .padding(.top, 12)

                slotPicker

                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10),
                    ],
                    spacing: 10
                ) {
                    ForEach(ownedAssets.filter { $0.slot == selectedSlot }) { asset in
                        BitePalAccessoryCard(accessory: asset.accessory, vm: vm)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                                    .fill(Color.card)
                            )
                    }
                }
                .padding(.horizontal, 12)
            }
            .padding(.bottom, 24)
        }
        .background(Color.background.ignoresSafeArea())
        .navigationTitle("Inventory")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var slotPicker: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(AccessoryCategory.allCases) { slot in
                        Button {
                            selectedSlot = slot
                        } label: {
                            Text(slot.displayName)
                                .font(.labelSmall)
                                .foregroundColor(selectedSlot == slot ? .white : .foreground)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule().fill(selectedSlot == slot ? slot.tint : Color.surfaceLight)
                                )
                        }
                        .buttonStyle(.plain)
                        .id(slot)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }
            .onChange(of: selectedSlot) { _, slot in
                withAnimation(.easeInOut(duration: 0.25)) {
                    proxy.scrollTo(slot, anchor: .center)
                }
            }
        }
    }
}

#Preview {
    NavigationStack { InventoryView() }
}
