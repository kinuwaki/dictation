import Foundation

// MARK: - DiffSegment

/// 差分表示の1セグメント
struct DiffSegment: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let type: SegmentType

    enum SegmentType: Equatable {
        case match      // 緑: 一致
        case close      // 黄: 惜しい（スペルミス）
        case missing    // 赤: 正解にあるがユーザー入力にない
        case extra      // 橙: ユーザー入力にあるが正解にない
    }
}

// MARK: - CheckResult

struct CheckResult: Equatable {
    let isCorrect: Bool
    let accuracy: Double        // 0.0〜1.0
    let diffSegments: [DiffSegment]

    static func == (lhs: CheckResult, rhs: CheckResult) -> Bool {
        lhs.isCorrect == rhs.isCorrect && lhs.accuracy == rhs.accuracy
    }
}

// MARK: - AnswerChecker

enum AnswerChecker {

    /// ファジーマッチの閾値: 編集距離が単語長のこの割合以下なら「惜しい」とみなす
    private static let fuzzyThreshold: Double = 0.35

    /// メイン判定メソッド
    static func check(userAnswer: String, correctAnswer: String, blanks: [String] = []) -> CheckResult {
        let userWords = normalize(userAnswer)
        let correctWords = normalize(correctAnswer)

        AppLogger.debug("[AnswerChecker] user入力: \"\(userAnswer)\"")
        AppLogger.debug("[AnswerChecker] 正解: \"\(correctAnswer)\"")
        AppLogger.debug("[AnswerChecker] blanks: \(blanks)")
        AppLogger.debug("[AnswerChecker] 正規化後user: \(userWords)")
        AppLogger.debug("[AnswerChecker] 正規化後correct: \(correctWords)")

        // 空入力チェック
        guard !correctWords.isEmpty else {
            return CheckResult(isCorrect: true, accuracy: 1.0, diffSegments: [])
        }

        if userWords.isEmpty {
            let segments = correctWords.map { DiffSegment(text: $0, type: .missing) }
            return CheckResult(isCorrect: false, accuracy: 0.0, diffSegments: segments)
        }

        // blanks がある場合: blank 部分のみで判定（穴埋め形式）
        if !blanks.isEmpty {
            let blankWords = blanks.flatMap { normalize($0) }
            if !blankWords.isEmpty {
                return checkWithBlanks(
                    userWords: userWords,
                    correctWords: correctWords,
                    blankWords: blankWords
                )
            }
        }

        // blanks がない場合: 全文比較
        let result = fuzzyCompare(userWords: userWords, correctWords: correctWords)
        let accuracy = result.score / Double(correctWords.count)
        let isCorrect = accuracy >= AppConfig.correctnessThreshold

        AppLogger.debug("[AnswerChecker] 全文比較: \(Int(accuracy * 100))%")

        return CheckResult(
            isCorrect: isCorrect,
            accuracy: accuracy,
            diffSegments: result.segments
        )
    }

    // MARK: - Blank-based Check

    /// blank 部分のみで正誤判定し、差分表示は blank 部分のみ表示
    private static func checkWithBlanks(
        userWords: [String],
        correctWords: [String],
        blankWords: [String]
    ) -> CheckResult {
        // ユーザー入力から blank に該当する単語を抽出
        // 方針: 正解全文からblank以外の単語を除外して、ユーザー入力のblank部分を特定する
        let extractedUserBlanks = extractUserBlanks(
            userWords: userWords,
            correctWords: correctWords,
            blankWords: blankWords
        )

        AppLogger.debug("[AnswerChecker] 抽出されたblank入力: \(extractedUserBlanks)")

        // blank 部分同士でファジー比較
        let result = fuzzyCompare(userWords: extractedUserBlanks, correctWords: blankWords)
        let accuracy = blankWords.isEmpty ? 1.0 : result.score / Double(blankWords.count)
        let isCorrect = accuracy >= AppConfig.correctnessThreshold

        AppLogger.debug("[AnswerChecker] blank比較: \(Int(accuracy * 100))%")

        return CheckResult(
            isCorrect: isCorrect,
            accuracy: accuracy,
            diffSegments: result.segments
        )
    }

    /// ユーザー入力から blank 部分に相当する単語を抽出する
    /// 正解の非blank単語をスキップして、blank位置にあるユーザー入力を取り出す
    private static func extractUserBlanks(
        userWords: [String],
        correctWords: [String],
        blankWords: [String]
    ) -> [String] {
        // 正解文中のどの位置が blank かを特定
        // 正解文: ["i","have","to","pick","up","my","son","and","his","friend","at","the","community","center","this","evening"]
        // blanks: ["my","son","and","his","friend"]
        // → blank位置: [5,6,7,8,9]

        var blankPositions = Set<Int>()
        var blankRemaining = blankWords
        for (idx, word) in correctWords.enumerated() {
            if let firstMatch = blankRemaining.firstIndex(of: word) {
                blankPositions.insert(idx)
                blankRemaining.remove(at: firstMatch)
            }
        }

        // 正解の非blank単語リスト（順序付き）
        let nonBlankWords = correctWords.enumerated()
            .filter { !blankPositions.contains($0.offset) }
            .map { $0.element }

        // ユーザー入力から非blank単語をマッチングして除去し、残りをblank入力とする
        // 非blank単語とユーザー入力でLCSを取り、マッチしなかったユーザー単語がblank入力
        var userIdx = 0
        var nonBlankIdx = 0
        var extracted: [String] = []

        while userIdx < userWords.count {
            if nonBlankIdx < nonBlankWords.count {
                let score = wordMatchScore(userWords[userIdx], nonBlankWords[nonBlankIdx])
                if score >= 1.0 {
                    // 非blank単語と完全一致 → スキップ
                    nonBlankIdx += 1
                    userIdx += 1
                } else {
                    // 一致しない → blank入力の候補
                    extracted.append(userWords[userIdx])
                    userIdx += 1
                }
            } else {
                // 非blank単語が全部消化済み → 残りはblank入力
                extracted.append(userWords[userIdx])
                userIdx += 1
            }
        }

        return extracted
    }

    // MARK: - Fuzzy Compare

    /// 単語配列をファジーマッチで比較し、スコアとdiffセグメントを返す
    private static func fuzzyCompare(userWords: [String], correctWords: [String]) -> (score: Double, segments: [DiffSegment]) {
        let m = userWords.count
        let n = correctWords.count

        if m == 0 {
            let segments = correctWords.map { DiffSegment(text: $0, type: .missing) }
            return (0, segments)
        }
        if n == 0 {
            let segments = userWords.map { DiffSegment(text: $0, type: .extra) }
            return (0, segments)
        }

        // DP: fuzzy LCS
        var dp = Array(repeating: Array(repeating: 0.0, count: n + 1), count: m + 1)
        var matchType = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)

        for i in 1...m {
            for j in 1...n {
                let wordScore = wordMatchScore(userWords[i - 1], correctWords[j - 1])
                if wordScore > 0 {
                    let diag = dp[i - 1][j - 1] + wordScore
                    if diag > dp[i - 1][j] && diag > dp[i][j - 1] {
                        dp[i][j] = diag
                        matchType[i][j] = wordScore >= 1.0 ? 1 : 2
                    } else if dp[i - 1][j] >= dp[i][j - 1] {
                        dp[i][j] = dp[i - 1][j]
                        matchType[i][j] = 0
                    } else {
                        dp[i][j] = dp[i][j - 1]
                        matchType[i][j] = 0
                    }
                } else {
                    if dp[i - 1][j] >= dp[i][j - 1] {
                        dp[i][j] = dp[i - 1][j]
                    } else {
                        dp[i][j] = dp[i][j - 1]
                    }
                    matchType[i][j] = 0
                }
            }
        }

        // バックトラック
        struct MatchPair {
            let userIdx: Int
            let correctIdx: Int
            let isExact: Bool
        }

        var matches: [MatchPair] = []
        var i = m, j = n
        while i > 0 && j > 0 {
            if matchType[i][j] == 1 || matchType[i][j] == 2 {
                matches.append(MatchPair(userIdx: i - 1, correctIdx: j - 1, isExact: matchType[i][j] == 1))
                i -= 1
                j -= 1
            } else if dp[i - 1][j] >= dp[i][j - 1] {
                i -= 1
            } else {
                j -= 1
            }
        }
        matches.reverse()

        // diff セグメント生成
        var segments: [DiffSegment] = []
        var ui = 0, ci = 0, mi = 0

        while ci < correctWords.count || ui < userWords.count {
            if mi < matches.count {
                let pair = matches[mi]

                while ci < pair.correctIdx {
                    segments.append(DiffSegment(text: correctWords[ci], type: .missing))
                    ci += 1
                }

                while ui < pair.userIdx {
                    segments.append(DiffSegment(text: userWords[ui], type: .extra))
                    ui += 1
                }

                if pair.isExact {
                    segments.append(DiffSegment(text: correctWords[ci], type: .match))
                } else {
                    segments.append(DiffSegment(text: "\(correctWords[ci])(\(userWords[ui]))", type: .close))
                }
                ci += 1
                ui += 1
                mi += 1
            } else {
                while ci < correctWords.count {
                    segments.append(DiffSegment(text: correctWords[ci], type: .missing))
                    ci += 1
                }
                while ui < userWords.count {
                    segments.append(DiffSegment(text: userWords[ui], type: .extra))
                    ui += 1
                }
            }
        }

        return (dp[m][n], segments)
    }

    /// 2つの単語のマッチスコアを返す
    private static func wordMatchScore(_ a: String, _ b: String) -> Double {
        if a == b { return 1.0 }

        let maxLen = max(a.count, b.count)
        guard maxLen > 0 else { return 1.0 }
        guard maxLen > 2 else { return 0.0 }

        let dist = levenshteinDistance(a, b)
        let ratio = Double(dist) / Double(maxLen)

        if ratio <= fuzzyThreshold {
            return 0.5
        }

        return 0.0
    }

    // MARK: - Levenshtein Distance

    private static func levenshteinDistance(_ a: String, _ b: String) -> Int {
        let aChars = Array(a)
        let bChars = Array(b)
        let m = aChars.count
        let n = bChars.count

        if m == 0 { return n }
        if n == 0 { return m }

        var prev = Array(0...n)
        var curr = Array(repeating: 0, count: n + 1)

        for i in 1...m {
            curr[0] = i
            for j in 1...n {
                let cost = aChars[i - 1] == bChars[j - 1] ? 0 : 1
                curr[j] = min(
                    prev[j] + 1,
                    curr[j - 1] + 1,
                    prev[j - 1] + cost
                )
            }
            prev = curr
        }

        return prev[n]
    }

    // MARK: - Normalization

    static func normalize(_ text: String) -> [String] {
        let lowered = text.lowercased()

        var cleaned = ""
        for char in lowered {
            if char.isLetter || char.isNumber || char.isWhitespace {
                cleaned.append(char)
            } else if char == "'" || char == "\u{2019}" || char == "\u{2018}" {
                cleaned.append("'")
            }
        }

        let result = cleaned
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }

        return result
    }
}
