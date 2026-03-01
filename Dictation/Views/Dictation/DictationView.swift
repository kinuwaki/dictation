import SwiftUI

// MARK: - DictationView（ディクテーション画面）

struct DictationView: View {
    let mode: DictationMode
    let allItems: [DictationItem]

    @Environment(\.dismiss) private var dismiss

    @StateObject private var vm = DictationViewModel()
    @State private var showResult = false

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            switch vm.phase {
            case .completed:
                Color.clear.onAppear {
                    if vm.isReviewMode {
                        dismiss()
                    } else {
                        showResult = true
                    }
                }
            default:
                questionContent
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            if vm.isExamMode {
                ToolbarItem(placement: .navigationBarTrailing) {
                    QuizTimerBadge(timerText: vm.timerText, isWarning: vm.isTimerWarning)
                }
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showResult, onDismiss: {
            dismiss()
        }) {
            NavigationStack {
                DictationResultView(
                    correctCount: vm.correctCount,
                    totalCount: vm.totalCount,
                    results: vm.sessionResults,
                    allItems: allItems,
                    isExamMode: vm.isExamMode,
                    onDismiss: { showResult = false }
                )
            }
        }
        .onAppear {
            vm.start(mode: mode, allItems: allItems)
        }
    }

    private var navigationTitle: String {
        switch mode {
        case .practice(let sourceLevel, let setIndex):
            // setIndex からサブレベルを逆引き
            if let sub = Level.allLevels().first(where: { $0.sourceLevel == sourceLevel && $0.setRange.contains(setIndex) }) {
                let displayIndex = sub.displaySetIndex(for: setIndex)
                return "\(sub.title) - セット\(displayIndex)"
            }
            return "セット\(setIndex)"
        case .review:  return "復習"
        case .exam(let sourceLevel):
            if let sub = Level.allLevels().first(where: { $0.sourceLevel == sourceLevel }) {
                return "\(sub.title)テスト"
            }
            return "テスト"
        case .daily:   return "今日の問題"
        }
    }

    // MARK: - Question content

    private var questionContent: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 16) {
                    // 問題カード（穴埋めヒント）
                    DictationQuestionCard(
                        questionText: vm.currentItem?.questionText ?? "",
                        progressText: vm.progressText
                    )
                    .id("question")

                    // 音声プレイヤー
                    if vm.canAnswer {
                        AudioPlayerCard(
                            audioManager: vm.audioManager,
                            onPlay: { vm.playAudio() }
                        )
                    }

                    // テキスト入力
                    if vm.canAnswer {
                        AnswerInputView(
                            text: $vm.userInput,
                            isDisabled: !vm.canAnswer,
                            onSubmit: { vm.submitAnswer() }
                        )
                    }

                    // スキップボタン（practiceのみ・回答前のみ）
                    if vm.isPracticeMode && vm.canAnswer {
                        GradientButton(
                            title: "この問題をスキップ  >",
                            gradientColors: AppColors.nextButtonGradient,
                            height: 52
                        ) {
                            vm.skip()
                        }
                    }

                    // フィードバック（回答後）
                    if !vm.canAnswer {
                        // 音声プレイヤー（答え合わせ中も再生可能）
                        AudioPlayerCard(
                            audioManager: vm.audioManager,
                            onPlay: { vm.playAudio() }
                        )

                        // 差分表示（スキップでない場合）
                        if let checkResult = vm.lastCheckResult {
                            DiffFeedbackView(
                                segments: checkResult.diffSegments,
                                isCorrect: checkResult.isCorrect,
                                accuracy: checkResult.accuracy
                            )
                            .id("feedback")
                        }

                        // 次の問題ボタン
                        GradientButton(
                            title: "次の問題へ",
                            gradientColors: AppColors.nextButtonGradient,
                            height: 56
                        ) {
                            vm.next()
                        }
                        .id("nextButton")

                        // 解説
                        if let item = vm.currentItem {
                            DictationExplanationView(
                                item: item,
                                isCorrect: vm.phase == .feedbackCorrect,
                                isSkipped: vm.lastResult?.userAnswer.isEmpty ?? true
                            )
                            .id("explanation")
                        }
                    }

                    Spacer()
                        .frame(height: 100)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .onChange(of: vm.canAnswer) { oldValue, newValue in
                if oldValue == true && newValue == false {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo("feedback", anchor: .top)
                    }
                }
            }
            .onChange(of: vm.currentIndex) { _, _ in
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo("question", anchor: .top)
                }
            }
        }
    }
}
