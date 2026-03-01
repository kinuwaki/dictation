import SwiftUI

// MARK: - ReviewListView

struct ReviewListView: View {
    let allItems: [DictationItem]

    @EnvironmentObject var progressStore: UserProgressStore
    @State private var showResetConfirm = false

    private var wrongCount: Int {
        progressStore.progress.wrongItemIDs.count
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 8) {
                Text("復習")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                Text("間違えた問題を復習しよう")
                    .font(.system(size: 15))
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()

            VStack(spacing: 14) {
                HStack(spacing: 10) {
                    Image(systemName: "scroll")
                        .font(.system(size: 20))
                        .foregroundStyle(AppColors.ballPartial)
                    Text("間違えた問題: \(wrongCount)問")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(AppColors.textPrimary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(AppColors.ballPartial.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                if wrongCount == 0 {
                    Text("復習を始める")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.gray.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    NavigationLink(value: DictationDestination(mode: .review)) {
                        Text("復習を始める")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                LinearGradient(
                                    colors: AppColors.reviewStartGradient,
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    showResetConfirm = true
                } label: {
                    Text("間違えた問題をリセット")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: AppColors.reviewResetGradient,
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.07), radius: 10, x: 0, y: 4)
            .padding(.horizontal, 20)

            Spacer()
            Spacer()
        }
        .background(AppColors.background)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("間違えた問題をすべてリセットしますか？", isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("リセットする", role: .destructive) {
                progressStore.update { $0.resetWrongItems() }
            }
            Button("キャンセル", role: .cancel) {}
        }
    }
}
