import Foundation

// MARK: - Level JSON 構造体

private struct LevelJSON: Decodable {
    let level: String
    let title: String
    let total: Int
    let questions: [LevelQuestionJSON]
}

private struct LevelQuestionJSON: Decodable {
    let id: Int
    let level: String
    let question_text: String
    let answer_text: String
    let blanks: [String]
    let japanese: String
    let pattern: String
    let explanation: String
}

// MARK: - DictationDataLoader

final class DictationDataLoader {
    static let shared = DictationDataLoader()
    private init() {}

    private var cachedItems: [DictationItem]?

    func load() -> [DictationItem] {
        if let cached = cachedItems { return cached }

        let levelFiles = AppConfig.levelFiles

        var allItems: [DictationItem] = []

        for filename in levelFiles {
            guard let url = Bundle.main.url(forResource: filename, withExtension: "json", subdirectory: "Assets/Dictation") else {
                AppLogger.warning("[DictationDataLoader] \(filename).json: URLが見つからない")
                continue
            }

            guard let data = try? Data(contentsOf: url) else {
                AppLogger.warning("[DictationDataLoader] \(filename).json: Data読み込み失敗")
                continue
            }

            do {
                let levelData = try JSONDecoder().decode(LevelJSON.self, from: data)

                let items = levelData.questions.map { q -> DictationItem in
                    let setIndex = (q.id - 1) / AppConstants.questionsPerSet + 1
                    return DictationItem(
                        id: "\(levelData.level)_\(q.id)",
                        level: levelData.level,
                        setIndex: setIndex,
                        questionText: q.question_text,
                        answerText: q.answer_text,
                        blanks: q.blanks,
                        japanese: q.japanese,
                        pattern: q.pattern,
                        explanation: q.explanation,
                        audioFile: "\(levelData.level)_\(String(format: "%03d", q.id)).mp3"
                    )
                }

                AppLogger.info("[DictationDataLoader] \(filename): \(items.count) 問読み込み完了")
                allItems.append(contentsOf: items)
            } catch {
                AppLogger.warning("[DictationDataLoader] \(filename).json: デコードエラー: \(error)")
            }
        }

        cachedItems = allItems
        return allItems
    }

    /// サブレベル一覧（AppConfig.subLevels から静的に生成）
    func levels(from items: [DictationItem]) -> [Level] {
        Level.allLevels()
    }
}
