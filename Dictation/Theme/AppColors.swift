import SwiftUI

// MARK: - AppColors

enum AppColors {
    // メインカラー（ティール系 — リスニング・集中イメージ）
    static let primary       = Color(red: 0.10, green: 0.45, blue: 0.55)  // #1A7A8C
    static let primaryLight  = Color(red: 0.30, green: 0.60, blue: 0.70)  // #4D99B3
    static let accent        = Color(red: 0.00, green: 0.55, blue: 0.60)  // #008C99
    static let background    = Color(red: 0.93, green: 0.96, blue: 0.97)  // #EDF5F8
    static let cardSurface   = Color.white

    // タブグラデーション
    static let tabGradient: [Color] = [
        Color(red: 0.10, green: 0.45, blue: 0.55),
        Color(red: 0.00, green: 0.55, blue: 0.60),
    ]

    // 正解・不正解
    static let correct        = Color(red: 0.30, green: 0.69, blue: 0.31)  // #4CAF50
    static let correctLight   = Color(red: 0.78, green: 0.90, blue: 0.79)  // #C8E6C9
    static let incorrect      = Color(red: 0.96, green: 0.26, blue: 0.21)  // #F44336
    static let incorrectLight = Color(red: 1.00, green: 0.80, blue: 0.82)  // #FFCDD2

    // 差分表示用（ディクテーション固有）
    static let diffMatch   = Color(red: 0.30, green: 0.69, blue: 0.31)  // 緑 - 一致
    static let diffClose   = Color(red: 0.95, green: 0.76, blue: 0.19)  // 黄 - 惜しい（スペルミス）
    static let diffMissing = Color(red: 0.96, green: 0.26, blue: 0.21)  // 赤 - 欠落
    static let diffExtra   = Color(red: 1.00, green: 0.60, blue: 0.00)  // 橙 - 余分

    // テキスト
    static let textPrimary   = Color(red: 0.13, green: 0.13, blue: 0.13)
    static let textSecondary = Color(red: 0.46, green: 0.46, blue: 0.46)

    // ボール（問題セット）色
    static let ballNotPlayed = Color(red: 0.62, green: 0.62, blue: 0.62)
    static let ballPartial   = Color(red: 0.90, green: 0.25, blue: 0.20)
    static let ballGood      = Color(red: 0.95, green: 0.75, blue: 0.00)
    static let ballPerfect   = Color(red: 0.20, green: 0.78, blue: 0.35)

    // MARK: - GradientButton / ThemeButton 用グラデーションカラー

    /// 次の問題へ / スキップ: ティール
    static let nextButtonGradient: [Color] = [
        Color(red: 0.10, green: 0.50, blue: 0.60),
        Color(red: 0.00, green: 0.65, blue: 0.70),
    ]

    /// レベル: ティール
    static let tealGradient: [Color] = [
        Color(red: 0.00, green: 0.59, blue: 0.53),
        Color(red: 0.00, green: 0.47, blue: 0.45),
    ]

    /// レベル: ブルー
    static let blueGradient: [Color] = [
        Color(red: 0.18, green: 0.50, blue: 0.91),
        Color(red: 0.00, green: 0.74, blue: 0.83),
    ]

    /// レベル: パープル
    static let purpleGradient: [Color] = [
        Color(red: 0.48, green: 0.30, blue: 0.93),
        Color(red: 0.61, green: 0.42, blue: 0.95),
    ]

    /// レベル: ピンク
    static let pinkGradient: [Color] = [
        Color(red: 1.00, green: 0.42, blue: 0.62),
        Color(red: 0.91, green: 0.12, blue: 0.39),
    ]

    /// レベル: グリーン
    static let greenGradient: [Color] = [
        Color(red: 0.61, green: 0.80, blue: 0.40),
        Color(red: 0.26, green: 0.63, blue: 0.28),
    ]

    /// カード収集: オレンジ系
    static let orangeGradient: [Color] = [
        Color(red: 1.00, green: 0.60, blue: 0.00),
        Color(red: 1.00, green: 0.34, blue: 0.13),
    ]

    /// インディゴ
    static let indigoGradient: [Color] = [
        Color(red: 0.25, green: 0.32, blue: 0.71),
        Color(red: 0.19, green: 0.25, blue: 0.62),
    ]

    // MARK: - タイマー色（テストモード）
    static let timerNormal  = Color(red: 1.00, green: 0.60, blue: 0.00)
    static let timerWarning = Color(red: 0.96, green: 0.26, blue: 0.21)

    // MARK: - 復習・設定画面用グラデーション
    static let reviewStartGradient: [Color] = [
        Color(red: 0.10, green: 0.45, blue: 0.55),
        Color(red: 0.00, green: 0.35, blue: 0.50)
    ]
    static let reviewResetGradient: [Color] = [
        Color(red: 0.95, green: 0.45, blue: 0.25),
        Color(red: 0.85, green: 0.25, blue: 0.15)
    ]

    // MARK: - 設定画面アイコン色
    static let settingsBell  = Color(red: 0.25, green: 0.55, blue: 0.95)
    static let settingsSound = Color(red: 0.55, green: 0.35, blue: 0.90)
    static let settingsStar  = Color(red: 0.95, green: 0.70, blue: 0.15)
    static let settingsShare = Color(red: 0.25, green: 0.75, blue: 0.35)
    static let settingsInfo  = Color(red: 0.95, green: 0.50, blue: 0.15)
    static let settingsReset = Color(red: 0.95, green: 0.30, blue: 0.30)

    // MARK: - 汎用色
    static let gray = Color(red: 0.62, green: 0.62, blue: 0.62)

    // MARK: - ガチャ・結果画面グラデーション

    static let gachaButtonGradient: [Color] = [
        Color(red: 0.10, green: 0.45, blue: 0.55),
        Color(red: 0.00, green: 0.55, blue: 0.60),
    ]

    static let commentGoodGradient: [Color] = [
        Color(red: 0.10, green: 0.45, blue: 0.55),
        Color(red: 0.30, green: 0.60, blue: 0.70),
    ]

    static let commentBadGradient: [Color] = [
        Color(red: 1.00, green: 0.60, blue: 0.00),
        Color(red: 1.00, green: 0.34, blue: 0.13),
    ]

    static let gachaCloseGradient: [Color] = [
        Color(red: 0.62, green: 0.62, blue: 0.62),
        Color(red: 0.74, green: 0.74, blue: 0.74),
    ]

    static let gachaNextGradient: [Color] = [
        Color(red: 0.10, green: 0.45, blue: 0.55),
        Color(red: 0.30, green: 0.60, blue: 0.70),
    ]

    // MARK: - パーティクル色

    static let sparkleLightPalette: [Color] = [
        Color(red: 0.10, green: 0.45, blue: 0.55),
        Color(red: 0.00, green: 0.55, blue: 0.60),
        Color(red: 0.85, green: 0.65, blue: 0.00),
        Color(red: 0.10, green: 0.50, blue: 0.60),
    ]

    static let sparkleDarkPalette: [Color] = [
        .white,
        Color(red: 1.0, green: 0.95, blue: 0.6),
        Color(red: 0.6, green: 0.8, blue: 1.0),
        Color(red: 0.7, green: 0.9, blue: 1.0),
    ]

    // MARK: - デバッグメニュー色

    static let debugOrange = Color(red: 0.95, green: 0.55, blue: 0.10)
    static let debugToggleTint = Color(red: 0.95, green: 0.60, blue: 0.10)

    // MARK: - ボタン無効色

    static let disabledBackground = Color(white: 0.87)
    static let disabledText = Color(white: 0.62)
}

// MARK: - LinearGradient shortcuts

extension LinearGradient {
    static var appTab: LinearGradient {
        LinearGradient(
            colors: AppColors.tabGradient,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var appNextButton: LinearGradient {
        LinearGradient(
            colors: AppColors.nextButtonGradient,
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static func appTheme(_ colors: [Color]) -> LinearGradient {
        LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
    }
}
