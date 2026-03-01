import Foundation

// MARK: - DictationItem

/// ディクテーション1問のデータ
struct DictationItem: Identifiable, Codable, Hashable {
    let id: String
    let level: String           // "level1", "level2", "level3"
    let setIndex: Int           // セット番号（1〜）
    let questionText: String    // 穴埋めヒント "______ ______ tired."
    let answerText: String      // 正解文 "I feel tired."
    let blanks: [String]        // ブランクの正解単語
    let japanese: String        // 日本語訳
    let pattern: String         // パターン名
    let explanation: String     // 解説
    let audioFile: String       // 音声ファイル名（なければTTSフォールバック）

    enum CodingKeys: String, CodingKey {
        case id, level
        case setIndex = "set_index"
        case questionText = "question_text"
        case answerText = "answer_text"
        case blanks, japanese, pattern, explanation
        case audioFile = "audio_file"
    }

    init(id: String, level: String, setIndex: Int, questionText: String, answerText: String,
         blanks: [String], japanese: String, pattern: String, explanation: String, audioFile: String) {
        self.id = id
        self.level = level
        self.setIndex = setIndex
        self.questionText = questionText
        self.answerText = answerText
        self.blanks = blanks
        self.japanese = japanese
        self.pattern = pattern
        self.explanation = explanation
        self.audioFile = audioFile
    }

    /// answer_text と blanks から穴埋めテキストを生成する
    /// blanks の連続する単語をまとめて検索し、単語境界で正確に置換する
    private static func buildQuestionText(answerText: String, blanks: [String], fallback: String) -> String {
        guard !blanks.isEmpty else { return answerText }

        // blanks を単語単位でまとめて1つの正規表現パターンにする
        // 例: ["I", "got", "angry"] → answer 内で "I got angry" を探して "______ ______ ______" に
        let words = answerText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        // 各単語から句読点を除去して比較用テキストを作る
        func stripped(_ s: String) -> String {
            s.lowercased().filter { $0.isLetter || $0.isNumber || $0 == "'" }
        }

        var blankIdx = 0
        var resultWords: [String] = []

        for word in words {
            if blankIdx < blanks.count && stripped(word) == stripped(blanks[blankIdx]) {
                resultWords.append("______")
                blankIdx += 1
            } else {
                resultWords.append(word)
            }
        }

        // マッチしなかった blanks が残る場合はフォールバック
        if blankIdx < blanks.count {
            return Self.formatDialogue(fallback)
        }

        return Self.formatDialogue(resultWords.joined(separator: " "))
    }

    /// 対話形式の "B:" の前に改行を挿入する
    private static func formatDialogue(_ text: String) -> String {
        // 正規表現で "B:" の前（空白や?/./!の直後）に改行を挿入
        var result = text
        if let range = result.range(of: #"\s+B:"#, options: .regularExpression) {
            result = result.replacingCharacters(in: range, with: "\nB:")
        } else if let range = result.range(of: #"\s+B："#, options: .regularExpression) {
            result = result.replacingCharacters(in: range, with: "\nB：")
        }
        return result
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let rawId = try c.decode(Int.self, forKey: .id)
        let lv = try c.decode(String.self, forKey: .level)
        self.id = "\(lv)_\(rawId)"
        self.level = lv
        // setIndex はデコード後に計算する（JSON にはない）
        self.setIndex = (rawId - 1) / AppConstants.questionsPerSet + 1
        let rawQuestionText = try c.decode(String.self, forKey: .questionText)
        let answer = try c.decode(String.self, forKey: .answerText)
        let blankWords = try c.decode([String].self, forKey: .blanks)
        self.answerText = DictationItem.formatDialogue(answer)
        self.blanks = blankWords
        // blanks から questionText を動的に生成（JSONの question_text は穴位置がずれている場合がある）
        self.questionText = DictationItem.buildQuestionText(answerText: answer, blanks: blankWords, fallback: rawQuestionText)
        self.japanese = try c.decode(String.self, forKey: .japanese)
        self.pattern = try c.decode(String.self, forKey: .pattern)
        self.explanation = try c.decode(String.self, forKey: .explanation)
        self.audioFile = (try? c.decode(String.self, forKey: .audioFile)) ?? "\(lv)_\(String(format: "%03d", rawId)).mp3"
    }
}

// MARK: - Level

/// サブレベル（トップメニューの1項目）
struct Level: Identifiable, Hashable {
    let name: String              // サブレベルID: "level1a", "level1b", etc.
    let title: String             // "初級1", "初級2", etc.
    let sourceLevel: String       // JSONのレベル名: "level1", "level2", "level3"
    let setRange: ClosedRange<Int> // このサブレベルに含まれるセット番号の範囲

    var id: String { name }

    var iconName: String {
        switch sourceLevel {
        case "level1": return "1.circle.fill"
        case "level2": return "2.circle.fill"
        case "level3": return "3.circle.fill"
        default:       return "questionmark.circle.fill"
        }
    }

    /// セット範囲内のセット数
    var totalSetCount: Int {
        setRange.upperBound - setRange.lowerBound + 1
    }

    /// このサブレベルに属するアイテムを取得
    func items(from allItems: [DictationItem]) -> [DictationItem] {
        allItems.filter { $0.level == sourceLevel && setRange.contains($0.setIndex) }
    }

    /// サブレベル内のセット番号を表示用に1始まりに変換
    func displaySetIndex(for realSetIndex: Int) -> Int {
        realSetIndex - setRange.lowerBound + 1
    }

    /// 表示用セット番号から実際のセット番号に変換
    func realSetIndex(for displayIndex: Int) -> Int {
        displayIndex + setRange.lowerBound - 1
    }

    /// レベルインデックスに応じたグラデーション
    static func gradientColors(for index: Int) -> [Color] {
        let palette: [[Color]] = [
            AppColors.tealGradient,
            AppColors.tealGradient,
            AppColors.tealGradient,
            AppColors.blueGradient,
            AppColors.blueGradient,
            AppColors.purpleGradient,
        ]
        return palette[index % palette.count]
    }

    /// AppConfig.subLevels から Level 一覧を生成
    static func allLevels() -> [Level] {
        AppConfig.subLevels.map { def in
            Level(
                name: def.id,
                title: def.title,
                sourceLevel: def.sourceLevel,
                setRange: def.setRange
            )
        }
    }
}

import SwiftUI
