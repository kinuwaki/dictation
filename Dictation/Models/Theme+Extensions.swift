import SwiftUI

// MARK: - Level Extensions

extension Level {
    /// サブレベルの日本語タイトル（title をそのまま使用）
    var displayTitle: String {
        title
    }

    /// レベル名に応じた説明
    var subtitle: String {
        switch sourceLevel {
        case "level1": return "基本的な英文パターン"
        case "level2": return "中級レベルの英文パターン"
        case "level3": return "上級レベルの英文パターン"
        default:       return ""
        }
    }
}
