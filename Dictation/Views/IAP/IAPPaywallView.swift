import SwiftUI

// MARK: - IAPPaywallView

struct IAPPaywallView: View {
    @EnvironmentObject var iapManager: IAPManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(LinearGradient.appTab)
                        .frame(width: 88, height: 88)
                    Image(systemName: "lock.open.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.white)
                }
                .padding(.top, 40)
                .padding(.bottom, 8)

                Text(AppConfig.paywallTitle)
                    .font(.system(size: 28, weight: .bold))
                    .kerning(-0.3)
                    .foregroundStyle(AppColors.textPrimary)
                    .padding(.bottom, 12)

                Text(AppConfig.paywallSubtitle)
                    .font(.system(size: 16))
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)

            VStack(alignment: .leading, spacing: 14) {
                ForEach(AppConfig.paywallBenefits.indices, id: \.self) { i in
                    let b = AppConfig.paywallBenefits[i]
                    let colors = [AppColors.blueGradient[0], AppColors.purpleGradient[0], AppColors.orangeGradient[0]]
                    benefitRow(icon: b.icon, color: colors[i % colors.count], text: b.text)
                }
            }
            .padding(20)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            .padding(.horizontal, 20)

            if let product = iapManager.product {
                VStack(spacing: 4) {
                    Text(product.displayPrice)
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                    Text("買い切り（永久利用）")
                        .font(.system(size: 15))
                        .foregroundStyle(AppColors.textSecondary)
                }
            }

            Button {
                guard !iapManager.isLoading else { return }
                Task {
                    let success = await iapManager.purchaseUnlock()
                    if success { dismiss() }
                }
            } label: {
                HStack(spacing: 8) {
                    Text(iapManager.isLoading ? "処理中..." : "購入する")
                        .font(.system(size: 18, weight: .bold))
                    if !iapManager.isLoading {
                        Text("App Store")
                            .font(.system(size: 15, weight: .regular))
                    }
                }
                .foregroundStyle(AppColors.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            }
            .disabled(iapManager.isLoading)
            .padding(.horizontal, 20)

            Button {
                Task {
                    await iapManager.restorePurchases()
                    if iapManager.isPurchased { dismiss() }
                }
            } label: {
                Text("購入を復元する")
                    .font(.system(size: 14))
                    .foregroundStyle(AppColors.textSecondary)
                    .underline()
            }
            .padding(.bottom, 20)
        }
        .background(AppColors.background)
        .presentationBackground(AppColors.background)
        .overlay(alignment: .topTrailing) {
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(AppColors.textSecondary.opacity(0.5))
            }
            .padding(16)
        }
        .alert("エラー", isPresented: .init(
            get: { iapManager.errorMessage != nil },
            set: { if !$0 { iapManager.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { iapManager.errorMessage = nil }
        } message: {
            Text(iapManager.errorMessage ?? "")
        }
    }

    private func benefitRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 17))
                    .foregroundStyle(color)
            }
            Text(text)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(AppColors.textPrimary)
        }
    }
}
