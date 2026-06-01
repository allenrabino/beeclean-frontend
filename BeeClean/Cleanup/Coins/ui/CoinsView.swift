import SwiftUI

// MARK: - Coins View
//
// Detail screen for the BeeClean coin balance. Shows the current
// balance, how it's earned (1 coin per 10 MB freed lifetime), and
// any bonus coins on top.
struct CoinsView: View {
    @ObservedObject private var stats = HiveStatsManager.shared

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 18) {
                balanceCard
                breakdownCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(Color.background.ignoresSafeArea())
        .navigationTitle("BeeCoins")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var balanceCard: some View {
        VStack(spacing: 14) {
            // Same coin as the dashboard + Progress — just scaled up.
            CoinBadge(size: 76)
                .padding(.top, 4)

            Text("\(stats.coinsBalance)")
                .font(.custom("Poppins-Bold", size: 52))
                .foregroundColor(Color(hex: "5A3D00"))
                .contentTransition(.numericText())
                .shadow(color: Color.white.opacity(0.4), radius: 0, x: 0, y: 1)

            Text("BEECOINS")
                .font(.custom("Poppins-Bold", size: 12))
                .tracking(2.4)
                .foregroundColor(Color(hex: "8A5A00").opacity(0.8))
        }
        .padding(.vertical, 30)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.xl, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "FFE066"), Color(hex: "FFC93C")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                // Diagonal specular sweep — gives the card a glossy
                // "freshly minted" sheen across the top-left.
                RoundedRectangle(cornerRadius: DesignTokens.Radius.xl, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.35), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .center
                        )
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.xl, style: .continuous)
                .stroke(Color.white.opacity(0.4), lineWidth: 0.8)
        )
        .shadow(color: Color(hex: "FFC93C").opacity(0.45), radius: 20, x: 0, y: 10)
    }

    private var breakdownCard: some View {
        // Earned ledger: coins actually awarded by cleanups (checkpoint
        // formula), the SAME value that drives the balance + Clean Bar — not
        // the old bytes/10MB derive, which disagreed with the pill.
        let earnedFromCleaning = ProgressManager.shared.totalLifetimeCoins
        let bonus = stats.bonusCoins

        return VStack(alignment: .leading, spacing: 12) {
            Text("Breakdown")
                .font(.titleSmall)
                .foregroundColor(.foreground)

            row(
                icon: "trash.fill",
                label: "From cleanups",
                value: "+\(earnedFromCleaning)",
                sub: "Earned reviewing & clearing clutter"
            )
            Divider()
            row(
                icon: "gift.fill",
                label: bonus >= 0 ? "Bonuses" : "Spent",
                value: bonus >= 0 ? "+\(bonus)" : "\(bonus)",
                sub: bonus >= 0 ? "Achievements & rewards" : "BitePal purchases"
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                .fill(Color.card)
        )
    }

    private func row(icon: String, label: String, value: String, sub: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.accentColor)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color.accentColor.opacity(0.15)))
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.labelMedium)
                    .foregroundColor(.foreground)
                Text(sub)
                    .font(.bodySmall)
                    .foregroundColor(.mutedForeground)
            }
            Spacer()
            Text(value)
                .font(.titleSmall)
                .foregroundColor(.foreground)
        }
    }

}

#Preview {
    NavigationStack { CoinsView() }
}
