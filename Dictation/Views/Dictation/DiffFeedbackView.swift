import SwiftUI

// MARK: - DiffFeedbackView

/// 差分カラー表示ビュー
struct DiffFeedbackView: View {
    let segments: [DiffSegment]
    let isCorrect: Bool
    let accuracy: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // ヘッダー
            HStack(spacing: 6) {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(isCorrect ? AppColors.correct : AppColors.incorrect)
                Text(isCorrect ? "正解！" : "不正解")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(isCorrect ? AppColors.correct : AppColors.incorrect)

                Spacer()

                // 正答率
                Text("\(Int(accuracy * 100))%")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(isCorrect ? AppColors.correct : AppColors.incorrect)
            }

            // 差分表示
            if !segments.isEmpty {
                WrappingHStack(segments: segments)
            }

            // 凡例
            if !isCorrect {
                let hasClose = segments.contains { $0.type == .close }
                HStack(spacing: 12) {
                    legendItem(color: AppColors.diffMatch, label: "一致")
                    if hasClose {
                        legendItem(color: AppColors.diffClose, label: "惜しい")
                    }
                    legendItem(color: AppColors.diffMissing, label: "聞き逃し")
                    legendItem(color: AppColors.diffExtra, label: "余分")
                }
                .font(.system(size: 12))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            isCorrect
                ? LinearGradient(colors: [AppColors.correctLight, AppColors.correct.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing)
                : LinearGradient(colors: [AppColors.incorrectLight, AppColors.incorrect.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isCorrect ? AppColors.correct : AppColors.incorrect, lineWidth: 1.5)
        )
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundStyle(AppColors.textSecondary)
        }
    }
}

// MARK: - WrappingHStack

/// 単語をフロー形式で折り返し表示
struct WrappingHStack: View {
    let segments: [DiffSegment]

    var body: some View {
        let attributedText = segments.reduce(Text("")) { result, segment in
            let color: Color = {
                switch segment.type {
                case .match:   return AppColors.diffMatch
                case .close:   return AppColors.diffClose
                case .missing: return AppColors.diffMissing
                case .extra:   return AppColors.diffExtra
                }
            }()
            let decoration: Text = {
                switch segment.type {
                case .match:
                    return Text(segment.text)
                        .foregroundColor(color)
                        .fontWeight(.medium)
                case .close:
                    return Text(segment.text)
                        .foregroundColor(color)
                        .fontWeight(.bold)
                case .missing:
                    return Text(segment.text)
                        .foregroundColor(color)
                        .fontWeight(.bold)
                case .extra:
                    return Text(segment.text)
                        .foregroundColor(color)
                        .fontWeight(.bold)
                        .underline()
                }
            }()
            return result + decoration + Text(" ")
        }

        attributedText
            .font(.system(size: 18))
            .lineSpacing(6)
            .fixedSize(horizontal: false, vertical: true)
    }
}
