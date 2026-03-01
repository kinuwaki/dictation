import SwiftUI

// MARK: - ExamOption

private struct ExamOption: Identifiable {
    let id: String        // sourceLevel: "level1", "level2", "level3"
    let title: String     // "初級", "中級", "上級"
    let iconName: String
    let gradient: [Color]
}

// MARK: - ExamSetupView

struct ExamSetupView: View {
    let allItems: [DictationItem]

    @EnvironmentObject var iapManager: IAPManager
    @EnvironmentObject var ownedStore: OwnedCardsStore
    @State private var showCollection = false
    @State private var showPaywall = false

    private var totalCardCount: Int { GachaCardLoader.shared.allCards.count }

    private let examOptions: [ExamOption] = [
        ExamOption(id: "level1", title: "初級", iconName: "1.circle.fill", gradient: AppColors.tealGradient),
        ExamOption(id: "level2", title: "中級", iconName: "2.circle.fill", gradient: AppColors.blueGradient),
        ExamOption(id: "level3", title: "上級", iconName: "3.circle.fill", gradient: AppColors.purpleGradient),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 6) {
                Text("実力テスト")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                Text("レベルを選んで開始（各\(AppConstants.examQuestionCount)問）")
                    .font(.system(size: 15))
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer().frame(height: 28)

            VStack(spacing: 12) {
                ForEach(examOptions) { opt in
                    let questionCount = allItems.filter { $0.level == opt.id }.count

                    if iapManager.isPurchased {
                        NavigationLink(value: DictationDestination(mode: .exam(level: opt.id))) {
                            examOptionRow(
                                title: "\(opt.title)テスト",
                                subtitle: "\(questionCount)問からランダム\(AppConstants.examQuestionCount)問出題",
                                iconName: opt.iconName,
                                gradient: opt.gradient,
                                isLocked: false
                            )
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button { showPaywall = true } label: {
                            examOptionRow(
                                title: "\(opt.title)テスト",
                                subtitle: "\(questionCount)問からランダム\(AppConstants.examQuestionCount)問出題",
                                iconName: opt.iconName,
                                gradient: opt.gradient,
                                isLocked: true
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.07), radius: 10, x: 0, y: 4)
            .padding(.horizontal, 20)

            Spacer().frame(height: 20)

            // カードコレクションバナー
            Button {
                showCollection = true
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.25))
                            .frame(width: 48, height: 48)
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("\(ownedStore.ownedIDs.count) / \(totalCardCount) 枚所有")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)
                        Text("テストクリアでカードをゲット")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.90))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
                .frame(height: 70)
                .background(
                    LinearGradient.appTheme(AppColors.orangeGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                )
                .shadow(color: AppColors.orangeGradient[0].opacity(0.30), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)

            Spacer()
            Spacer()
        }
        .background(AppColors.background)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) {
            IAPPaywallView()
                .environmentObject(iapManager)
        }
        .navigationDestination(isPresented: $showCollection) {
            CardCollectionScreen()
        }
    }

    private func examOptionRow(title: String, subtitle: String, iconName: String, gradient: [Color], isLocked: Bool) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.30))
                    .frame(width: 48, height: 48)
                Image(systemName: iconName)
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.90))
            }
            Spacer()
            Image(systemName: isLocked ? "lock.fill" : "chevron.right")
                .font(.system(size: isLocked ? 20 : 16, weight: .semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .frame(height: 70)
        .background(
            LinearGradient.appTheme(gradient)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        )
        .shadow(color: gradient[0].opacity(0.25), radius: 6, x: 0, y: 3)
    }
}
