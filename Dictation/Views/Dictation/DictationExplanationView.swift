import SwiftUI

// MARK: - DictationExplanationView

struct DictationExplanationView: View {
    let item: DictationItem
    let isCorrect: Bool
    let isSkipped: Bool

    private var accentColor: Color {
        (isSkipped || isCorrect) ? AppColors.correct : AppColors.incorrect
    }

    private var bgGradient: LinearGradient {
        if isSkipped || isCorrect {
            return LinearGradient(
                colors: [AppColors.correctLight, AppColors.correct.opacity(0.08)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [AppColors.incorrectLight, AppColors.incorrect.opacity(0.08)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 正解文
            VStack(alignment: .leading, spacing: 4) {
                Text("正解")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColors.textSecondary)
                Text(item.answerText)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
            }

            Divider()

            // 日本語訳
            VStack(alignment: .leading, spacing: 4) {
                Text("日本語訳")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColors.textSecondary)
                Text(item.japanese)
                    .font(.system(size: 16))
                    .foregroundStyle(AppColors.textPrimary)
            }

            // パターン
            HStack(spacing: 6) {
                Text(item.pattern)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppColors.primary)
                    .clipShape(Capsule())
            }

            // 解説
            if !item.explanation.isEmpty {
                Text(item.explanation)
                    .font(.system(size: 15))
                    .foregroundStyle(AppColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 4)
    }
}
