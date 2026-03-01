import Foundation

// MARK: - AppConstants

/// アプリ全体で使用する定数を集約
enum AppConstants {

    // MARK: - Quiz Timing

    /// テストモード: 1問あたりの制限時間（秒）
    static let secondsPerQuestion = 60

    /// タイマー警告表示の閾値（秒）
    static let timerWarningThreshold = 60

    // MARK: - Quiz Structure

    /// 1セットあたりの問題数
    static let questionsPerSet = 5

    // MARK: - IAP / Free Limits

    /// 無料で利用可能なセット数（各サブレベル内で2セットまで無料）
    static let freeSetLimit = 2

    /// テストモード: 1回あたりの出題数
    static let examQuestionCount = 5

    // MARK: - Gacha Rewards

    /// 問題数に応じたガチャカード枚数
    static let gachaRewardThresholds: [(minQuestions: Int, cardCount: Int)] = [
        (minQuestions: 30, cardCount: 4),
        (minQuestions: 20, cardCount: 2),
        (minQuestions: 0,  cardCount: 1)
    ]

    /// ガチャカード枚数を計算
    static func gachaCardCount(for totalQuestions: Int) -> Int {
        for threshold in gachaRewardThresholds {
            if totalQuestions >= threshold.minQuestions {
                return threshold.cardCount
            }
        }
        return 1
    }
}
