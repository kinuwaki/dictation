import SwiftUI

// MARK: - DictationQuestionCard

/// ディクテーション問題カード（穴埋めヒントと進捗表示）
struct DictationQuestionCard: View {
    let questionText: String
    let progressText: String

    var body: some View {
        VStack(spacing: 12) {
            // 進捗ラベル
            Text(progressText)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppColors.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(AppColors.primary.opacity(0.12))
                .clipShape(Capsule())

            // 穴埋めヒント
            Text(questionText)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(questionText.contains("B:") ? .leading : .center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: questionText.contains("B:") ? .leading : .center)
                .padding(.horizontal, 8)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(AppColors.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 4)
    }
}
