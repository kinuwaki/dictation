import Foundation

// MARK: - GachaCard

struct GachaCard: Identifiable, Codable, Hashable {
    let id: String
    let filename: String
    let title: String
    let category: String
    let grade: String       // "共通" / "初級" / "中級" / "上級"
}

// MARK: - GachaCardLoader

final class GachaCardLoader {
    static let shared = GachaCardLoader()
    private init() {}

    private var _cards: [GachaCard]?

    var allCards: [GachaCard] {
        if let c = _cards { return c }
        let loaded = load()
        _cards = loaded
        return loaded
    }

    /// sourceLevel に対応する共通＋級別カードを返す
    func cards(forLevel sourceLevel: String) -> [GachaCard] {
        let grade = AppConfig.cardGrade(for: sourceLevel)
        return allCards.filter { $0.grade == AppConfig.cardCategoryCommon || $0.grade == grade }
    }

    private func load() -> [GachaCard] {
        guard
            let url = Bundle.main.url(forResource: "card_list", withExtension: "csv", subdirectory: "Assets/Cards"),
            let raw = try? String(contentsOf: url, encoding: .utf8)
        else {
            AppLogger.warning("[GachaCardLoader] card_list.csv の読み込みに失敗")
            return []
        }

        var lines = raw.components(separatedBy: "\n")
        if let first = lines.first {
            lines[0] = first.trimmingCharacters(in: .init(charactersIn: "\u{FEFF}"))
        }
        guard lines.count > 1 else { return [] }

        return lines.dropFirst().compactMap { line -> GachaCard? in
            let cols = line.components(separatedBy: ",")
            guard cols.count >= 5 else { return nil }
            let no       = cols[0].trimmingCharacters(in: .whitespaces)
            let filename = cols[1].trimmingCharacters(in: .whitespaces)
            let title    = cols[2].trimmingCharacters(in: .whitespaces)
            let category = cols[3].trimmingCharacters(in: .whitespaces)
            let grade    = cols[4].trimmingCharacters(in: .whitespaces)
            guard !no.isEmpty else { return nil }
            return GachaCard(id: no, filename: filename, title: title, category: category, grade: grade)
        }
    }
}
