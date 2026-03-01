import SwiftUI

// MARK: - DictationResultView

struct DictationResultView: View {
    let correctCount: Int
    let totalCount: Int
    let results: [DictationResult]
    let allItems: [DictationItem]
    let isExamMode: Bool
    let onDismiss: () -> Void

    @State private var gachaAlreadyPulled: Bool = false
    @State private var showGacha: Bool = false
    @State private var gachaCardCount: Int = 1

    private var accuracyRate: Double {
        guard totalCount > 0 else { return 0 }
        return Double(correctCount) / Double(totalCount)
    }

    private var accuracyPercent: Int { Int(accuracyRate * 100) }

    private var rankLabel: String {
        AppConfig.rankLabel(for: accuracyPercent)
    }

    private var rankColor: Color {
        switch accuracyPercent {
        case 100:   return AppColors.ballPerfect
        case 80...: return AppColors.ballGood
        case 60...: return AppColors.ballPartial
        default:    return AppColors.ballPartial
        }
    }

    private var isGachaEligible: Bool {
        isExamMode && accuracyPercent >= AppConfig.gachaMinAccuracy && !gachaAlreadyPulled
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                scoreSection

                if isExamMode {
                    examCommentCard
                }

                if isExamMode {
                    if isGachaEligible {
                        gachaButton
                    } else {
                        GradientButton(
                            title: "もどる",
                            gradientColors: AppColors.greenGradient,
                            height: 52
                        ) {
                            onDismiss()
                        }
                    }
                } else {
                    GradientButton(
                        title: "もどる",
                        gradientColors: AppColors.greenGradient,
                        height: 52
                    ) {
                        onDismiss()
                    }
                }

                answersSection
                Spacer(minLength: 32)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
        }
        .background(AppColors.background)
        .navigationTitle("結果")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .fullScreenCover(isPresented: $showGacha) {
            CardGachaScreen(cardCount: gachaCardCount) {
                showGacha = false
                onDismiss()
            }
        }
    }

    // MARK: - Score section

    private var scoreSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color(UIColor.systemGray5), lineWidth: 14)
                    .frame(width: 160, height: 160)

                Circle()
                    .trim(from: 0, to: accuracyRate)
                    .stroke(rankColor, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 160, height: 160)
                    .animation(.easeInOut(duration: 0.8), value: accuracyRate)

                VStack(spacing: 2) {
                    Text("\(accuracyPercent)%")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundStyle(rankColor)
                    Text("\(correctCount) / \(totalCount) 問")
                        .font(.system(size: 14))
                        .foregroundStyle(AppColors.textSecondary)
                }
            }

            Text(rankLabel)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(rankColor)
        }
        .padding(24)
        .background(AppColors.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 4)
    }

    // MARK: - Exam comment card

    private var examCommentCard: some View {
        let comment = AppConfig.examComment(for: accuracyPercent)
        let gradientColors: [Color] = comment.isGood
            ? AppColors.commentGoodGradient
            : AppColors.commentBadGradient
        let iconName = comment.isGood ? "star.fill" : "book.fill"

        return HStack(alignment: .top, spacing: 14) {
            Image(systemName: iconName)
                .font(.system(size: 28))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text("テスト結果コメント")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColors.textSecondary)
                Text(comment.message)
                    .font(.system(size: 15))
                    .foregroundStyle(AppColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(16)
        .background(AppColors.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 4)
    }

    // MARK: - Gacha button

    private var gachaButton: some View {
        let cardCount = GachaEngine.cardCount(for: totalCount)
        return VStack(spacing: 8) {
            Text(AppConfig.gachaChallengeLabel)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppColors.textSecondary)
            GradientButton(
                title: "\(AppConfig.gachaDrawLabel)\(cardCount)枚引く",
                gradientColors: AppColors.gachaButtonGradient,
                height: 56
            ) {
                pullGacha(count: cardCount)
            }
        }
    }

    private func pullGacha(count: Int) {
        gachaCardCount = count
        gachaAlreadyPulled = true
        showGacha = true
    }

    // MARK: - Answers list

    private var answersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("回答一覧")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)

            ForEach(results.indices, id: \.self) { idx in
                let result = results[idx]
                if let item = allItems.first(where: { $0.id == result.itemID }) {
                    DictationResultRowView(index: idx + 1, item: item, result: result)
                }
            }
        }
    }
}

// MARK: - DictationResultRowView

struct DictationResultRowView: View {
    let index: Int
    let item: DictationItem
    let result: DictationResult

    private var isSkipped: Bool { result.userAnswer.isEmpty }

    private var iconName: String {
        if isSkipped { return "arrow.forward.circle.fill" }
        return result.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill"
    }

    private var iconColor: Color {
        if isSkipped { return AppColors.textSecondary }
        return result.isCorrect ? AppColors.correct : AppColors.incorrect
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: iconName)
                .font(.system(size: 20))
                .foregroundStyle(iconColor)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 3) {
                Text("Q\(index). \(item.questionText)")
                    .font(.system(size: 14))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(2)

                if !result.isCorrect && !isSkipped {
                    Text("正解: \(item.answerText)")
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.correct)
                }

                if !isSkipped {
                    Text("正答率: \(Int(result.accuracy * 100))%")
                        .font(.system(size: 11))
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
        }
        .padding(12)
        .background(AppColors.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
