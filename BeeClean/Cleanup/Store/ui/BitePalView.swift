import SwiftUI

// MARK: - BitePal View
//
// Accessory shop presented as a bottom sheet over the homepage bee
// (BitePal-style). The hero preview lives on the dashboard — this view
// is category tabs + item grid only.
struct BitePalView: View {
    @StateObject private var vm = BitePalViewModel.shared
    @ObservedObject private var stats = HiveStatsManager.shared
    @State private var selectedCategory: AccessoryCategory = .hats

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                sheetHeader
                categoryTabs
                ScrollView(.vertical, showsIndicators: false) {
                    grid
                }
            }
            .background(Color.white.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
        .onAppear { vm.setShopSheetPresented(true) }
        .onDisappear { vm.setShopSheetPresented(false) }
        .task { await vm.pullRemoteIfNeeded() }
    }

    // MARK: Sheet Header

    private var sheetHeader: some View {
        HStack(alignment: .center, spacing: 8) {
            if vm.previewAccessoryId != nil {
                Text("Previewing — tap again to clear")
                    .font(.bodySmall)
                    .foregroundColor(.mutedForeground)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)

            HStack(spacing: 6) {
                Image(systemName: "bitcoinsign.circle.fill")
                    .foregroundStyle(LinearGradient.honeyGradient)
                Text("\(stats.coinsBalance)")
                    .font(.labelMedium)
                    .foregroundColor(.foreground)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color(hex: "F2F2F7")))

            NavigationLink {
                InventoryView()
            } label: {
                Image(systemName: "archivebox.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.foreground)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color(hex: "F2F2F7")))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 8)
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
                .padding(.vertical, 10)
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
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.black.opacity(0.08))
                .frame(height: 0.5)
        }
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
            VStack(spacing: 6) {
                Image(systemName: category.sfSymbol)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(isSelected ? category.tint : .mutedForeground)

                if isSelected {
                    Capsule()
                        .fill(Color.foreground)
                        .frame(width: 28, height: 3)
                } else {
                    Color.clear.frame(width: 28, height: 3)
                }
            }
            .frame(width: 52)
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
                            .fill(Color(hex: "F5F5F7"))
                    )
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 12)
        .padding(.bottom, 24)
    }
}

#Preview {
    BitePalView()
}
