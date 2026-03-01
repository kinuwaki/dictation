import Foundation

// MARK: - UserProgress

/// ユーザーの進捗データ（UserDefaultsに1つのJSONとして保存）
struct UserProgress: Codable {
    /// 間違えた問題IDのセット
    var wrongItemIDs: Set<String> = []

    /// 完了済み問題セット（"level/setIndex" 形式）
    var completedSets: Set<String> = []

    /// セットごとの正答率記録（"level/setIndex" -> 正答率 0.0〜1.0）
    var setAccuracyRates: [String: Double] = [:]

    /// 累計回答数
    var totalAnswered: Int = 0

    /// 累計正解数
    var totalCorrect: Int = 0

    // MARK: - Helpers

    static func setKey(level: String, setIndex: Int) -> String {
        "\(level)/\(setIndex)"
    }

    /// セットの進捗状態（3段階）
    enum SetProgress {
        case notPlayed
        case partial    // 正答率 0〜59%
        case good       // 正答率 60〜99%
        case perfect    // 正答率 100%
    }

    func progress(for key: String) -> SetProgress {
        guard completedSets.contains(key), let rate = setAccuracyRates[key] else {
            return .notPlayed
        }
        if rate >= 1.0 { return .perfect }
        if rate >= 0.6 { return .good }
        return .partial
    }

    mutating func markSetCompleted(level: String, setIndex: Int, correct: Int, total: Int) {
        let key = Self.setKey(level: level, setIndex: setIndex)
        completedSets.insert(key)
        setAccuracyRates[key] = total > 0 ? Double(correct) / Double(total) : 0
        totalAnswered += total
        totalCorrect += correct
    }

    mutating func addWrong(id: String) {
        wrongItemIDs.insert(id)
    }

    mutating func removeWrong(id: String) {
        wrongItemIDs.remove(id)
    }

    mutating func resetWrongItems() {
        wrongItemIDs = []
    }
}

// MARK: - UserProgressStore

/// UserDefaultsへの読み書きを担う
final class UserProgressStore: ObservableObject {
    static let shared = UserProgressStore()
    private let key = AppConfig.Keys.userProgress

    @Published private(set) var progress: UserProgress = UserProgress()

    private init() { load() }

    func load() {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let decoded = try? JSONDecoder().decode(UserProgress.self, from: data)
        else { return }
        progress = decoded
    }

    func save() {
        guard let data = try? JSONEncoder().encode(progress) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    func update(_ block: (inout UserProgress) -> Void) {
        var copy = progress
        block(&copy)
        progress = copy
        save()
    }

    func reset() {
        progress = UserProgress()
        save()
    }
}
