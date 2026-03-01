import Foundation

// MARK: - DictationMode

enum DictationMode: Equatable {
    case practice(level: String, setIndex: Int)  // レベル・問題セット指定
    case review                                   // 間違えた問題から
    case exam(level: String)                      // レベル別テスト（20問）
    case daily(itemId: String)                   // 通知タップ → 1問モード
}

// MARK: - DictationPhase

/// ディクテーション画面の状態
enum DictationPhase: Equatable {
    case listening          // 音声聞き取り中・入力待ち
    case feedbackCorrect    // 正解フィードバック
    case feedbackWrong      // 不正解フィードバック
    case completed          // 全問完了
}

// MARK: - DictationResult

struct DictationResult: Equatable {
    let itemID: String
    let userAnswer: String
    let isCorrect: Bool
    let accuracy: Double   // 0.0〜1.0
}
