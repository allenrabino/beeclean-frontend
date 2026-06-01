import SwiftUI

// MARK: - BitePal View
//
// The accessory shop. Modeled on the BitePal raccoon-store reference:
//   • Top hero — bee preview with whatever's equipped, name, hearts,
//     and a coin balance pill on the trailing edge.
//   • Category tab strip — one icon per AccessoryCategory.
//   • Grid of accessory cards filtered to the selected category.
struct BitePalView: View {
    @StateObject private var vm = BitePalViewModel.shared
    @ObservedObject private var stats = HiveStatsManager.shared
    @State private var selectedCategory: AccessoryCategory = .hats

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                hero
                categoryTabs
                grid
            }
        }
        .background(
            LinearGradient(
                colors: [Color(hex: "FFE066"), Color(hex: "FFC93C")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationTitle("BitePal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("BitePal")
                    .font(.titleMedium)
                    .foregroundColor(.foreground)
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    InventoryView()
                } label: {
                    Image(systemName: "archivebox.fill")
                }
            }
        }
        .task { await vm.pullRemoteIfNeeded() }
    }

    // MARK: Hero

    private var hero: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 12) {
                BeeAvatarView(equippedAssetIds: vm.displayEquippedIds, size: 200)
                    .frame(height: 220)
                    .animation(.spring(response: 0.35, dampingFraction: 0.82), value: vm.displayEquippedIds)

                Text("Caramel")
                    .font(.titleLarge)
                    .foregroundColor(.foreground)

                HStack(spacing: 6) {
                    ForEach(0..<4) { i in
                        Image(systemName: i < 1 ? "heart.fill" : "heart")
                            .foregroundColor(i < 1 ? .red : .red.opacity(0.4))
                    }
                }

                if vm.previewAccessoryId != nil {
                    Text("Previewing — tap item again to clear")
                        .font(.bodySmall)
                        .foregroundColor(.foreground.opacity(0.72))
                }
            }
            .padding(.top, 28)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity)

            HStack(spacing: 6) {
                Image(systemName: "bitcoinsign.circle.fill")
                    .foregroundStyle(LinearGradient.honeyGradient)
                Text("\(stats.coinsBalance)")
                    .font(.labelMedium)
                    .foregroundColor(.foreground)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.white.opacity(0.85)))
            .padding(.trailing, 16)
            .padding(.top, 12)
        }
    }

    // MARK: Category Tabs

    private var categoryTabs: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(AccessoryCategory.allCases) { category in
                        categoryTabButton(category)
                            .id(category)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .onAppear {
                proxy.scrollTo(selectedCategory, anchor: .center)
            }
            .onChange(of: selectedCategory) { _, category in
                withAnimation(.easeInOut(duration: 0.25)) {
                    proxy.scrollTo(category, anchor: .center)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.xl, style: .continuous)
                .fill(Color.white.opacity(0.45))
        )
        .padding(.horizontal, 12)
    }

    private func categoryTabButton(_ category: AccessoryCategory) -> some View {
        let isSelected = selectedCategory == category

        return Button {
            HapticManager.shared.buttonTap()
            withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                selectedCategory = category
            }
            vm.clearPreview()
        } label: {
            VStack(spacing: 5) {
                Image(systemName: category.sfSymbol)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(isSelected ? .white : category.tint)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle().fill(isSelected ? category.tint : Color.white.opacity(0.9))
                    )

                Text(category.displayName)
                    .font(.labelSmall)
                    .foregroundColor(.foreground)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .frame(width: 58)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Grid

    private var grid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10),
            ],
            spacing: 10
        ) {
            ForEach(BeeAccessoryCatalog.items(in: selectedCategory)) { accessory in
                BitePalAccessoryCard(accessory: accessory, vm: vm)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                            .fill(Color.card)
                    )
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 14)
        .padding(.bottom, 24)
    }
}

#Preview {
    NavigationStack {
        BitePalView()
    }
}
