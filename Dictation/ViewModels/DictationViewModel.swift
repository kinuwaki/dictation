import Foundation
import Combine

// MARK: - DictationViewModel

@MainActor
final class DictationViewModel: ObservableObject {

    // MARK: - Published state

    @Published private(set) var phase: DictationPhase = .listening
    @Published private(set) var currentItem: DictationItem?
    @Published private(set) var currentIndex: Int = 0
    @Published private(set) var totalCount: Int = 0
    @Published private(set) var correctCount: Int = 0
    @Published private(set) var lastResult: DictationResult?
    @Published private(set) var lastCheckResult: CheckResult?
    @Published private(set) var canAnswer: Bool = true
    @Published private(set) var sessionResults: [DictationResult] = []
    @Published var userInput: String = ""

    // MARK: - Audio

    @Published var audioManager = AudioPlaybackManager()

    // MARK: - Timer（テストモード専用）

    @Published private(set) var remainingSeconds: Int = 0
    @Published private(set) var isTimerRunning: Bool = false

    private var timerCancellable: AnyCancellable?

    // MARK: - Private

    private var items: [DictationItem] = []
    private var mode: DictationMode = .exam(level: "level1")
    private let progressStore: UserProgressStore

    // MARK: - Init

    init(progressStore: UserProgressStore = .shared) {
        self.progressStore = progressStore
    }

    // MARK: - Session setup

    func start(mode: DictationMode, allItems: [DictationItem]) {
        self.mode = mode
        self.items = buildItemList(mode: mode, allItems: allItems)
        self.currentIndex = 0
        self.correctCount = 0
        self.sessionResults = []
        self.lastResult = nil
        self.lastCheckResult = nil
        self.canAnswer = true
        self.userInput = ""
        self.phase = .listening
        self.totalCount = items.count
        self.currentItem = items.first

        // 音声ロード
        if let item = items.first {
            audioManager.load(audioFile: item.audioFile, text: item.answerText)
        }

        // テストモードはタイマーなし
    }

    private func buildItemList(mode: DictationMode, allItems: [DictationItem]) -> [DictationItem] {
        switch mode {
        case .practice(let level, let setIndex):
            return allItems
                .filter { $0.level == level && $0.setIndex == setIndex }
                .shuffled()
        case .review:
            let wrongIDs = progressStore.progress.wrongItemIDs
            return allItems
                .filter { wrongIDs.contains($0.id) }
                .shuffled()
        case .exam(let level):
            return Array(
                allItems.filter { $0.level == level }
                    .shuffled()
                    .prefix(AppConstants.examQuestionCount)
            )
        case .daily(let itemId):
            if let item = allItems.first(where: { $0.id == itemId }) {
                return [item]
            }
            return allItems.randomElement().map { [$0] } ?? []
        }
    }

    // MARK: - Timer

    private func startTimer(seconds: Int) {
        remainingSeconds = seconds
        isTimerRunning = true

        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                if self.remainingSeconds > 0 {
                    self.remainingSeconds -= 1
                } else {
                    self.stopTimer()
                    self.finishSession()
                }
            }
    }

    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
        isTimerRunning = false
    }

    var timerText: String {
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    var isTimerWarning: Bool {
        remainingSeconds <= AppConstants.timerWarningThreshold
    }

    // MARK: - Submit Answer

    func submitAnswer() {
        guard canAnswer, let item = currentItem else { return }
        canAnswer = false

        let checkResult = AnswerChecker.check(userAnswer: userInput, correctAnswer: item.answerText, blanks: item.blanks)
        lastCheckResult = checkResult

        let result = DictationResult(
            itemID: item.id,
            userAnswer: userInput,
            isCorrect: checkResult.isCorrect,
            accuracy: checkResult.accuracy
        )
        lastResult = result
        sessionResults.append(result)

        if checkResult.isCorrect {
            correctCount += 1
            phase = .feedbackCorrect
            SoundManager.shared.play(.correct)
            progressStore.update { $0.removeWrong(id: item.id) }
        } else {
            phase = .feedbackWrong
            // 8割以上正解ならピンポン（惜しい！）、それ未満ならブザー
            SoundManager.shared.play(checkResult.accuracy >= 0.80 ? .correct : .wrong)
            progressStore.update { $0.addWrong(id: item.id) }
        }

        // 再生停止
        audioManager.stop()

        // デバッグ: テスト自動攻略
        if UserDefaults.standard.bool(forKey: AppConfig.Keys.debugAutoClear) {
            autoClearRemaining()
        }
    }

    /// スキップ
    func skip() {
        guard canAnswer, let item = currentItem else { return }
        canAnswer = false
        let result = DictationResult(itemID: item.id, userAnswer: "", isCorrect: false, accuracy: 0)
        lastResult = result
        lastCheckResult = nil
        sessionResults.append(result)
        phase = .feedbackCorrect  // スキップは解説を緑で表示
        audioManager.stop()
    }

    /// 残り問題を全問正解扱いでセッション終了
    private func autoClearRemaining() {
        let nextIndex = currentIndex + 1
        guard nextIndex < items.count else { return }
        for i in nextIndex..<items.count {
            let item = items[i]
            let result = DictationResult(itemID: item.id, userAnswer: item.answerText, isCorrect: true, accuracy: 1.0)
            sessionResults.append(result)
            correctCount += 1
            progressStore.update { $0.removeWrong(id: item.id) }
        }
        currentIndex = items.count - 1
        finishSession()
    }

    // MARK: - Next

    func next() {
        let nextIndex = currentIndex + 1
        if nextIndex >= items.count {
            finishSession()
            return
        }
        currentIndex = nextIndex
        currentItem = items[nextIndex]
        lastResult = nil
        lastCheckResult = nil
        canAnswer = true
        userInput = ""
        phase = .listening

        // 次の問題の音声をロード
        audioManager.load(audioFile: items[nextIndex].audioFile, text: items[nextIndex].answerText)
    }

    // MARK: - Finish

    private func finishSession() {
        stopTimer()
        audioManager.stop()

        switch mode {
        case .practice(let level, let setIndex):
            progressStore.update {
                $0.markSetCompleted(
                    level: level,
                    setIndex: setIndex,
                    correct: correctCount,
                    total: totalCount
                )
            }
        default:
            progressStore.update {
                $0.totalAnswered += totalCount
                $0.totalCorrect += correctCount
            }
        }
        phase = .completed
    }

    // MARK: - Play Audio

    func playAudio() {
        guard let item = currentItem else { return }
        audioManager.play(text: item.answerText)
    }

    // MARK: - Computed

    var accuracyRate: Double {
        guard totalCount > 0 else { return 0 }
        return Double(correctCount) / Double(totalCount)
    }

    var progressText: String {
        "問題 \(currentIndex + 1) / \(totalCount)"
    }

    var isPracticeMode: Bool {
        if case .practice = mode { return true }
        return false
    }

    var isReviewMode: Bool {
        if case .review = mode { return true }
        return false
    }

    var isExamMode: Bool {
        if case .exam = mode { return true }
        return false
    }

    var isDailyMode: Bool {
        if case .daily = mode { return true }
        return false
    }
}
