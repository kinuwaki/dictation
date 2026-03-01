import Foundation

// MARK: - GachaEngine

enum GachaEngine {

    static func cardCount(for totalQuestions: Int) -> Int {
        AppConstants.gachaCardCount(for: totalQuestions)
    }
}
