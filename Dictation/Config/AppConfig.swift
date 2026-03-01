import Foundation

// MARK: - AppConfig

/// アプリ固有の設定値を一元管理するファイル。
enum AppConfig {

    // MARK: - App Identity

    static let appName = "英語ディクテーション"

    // MARK: - UserDefaults Keys

    enum Keys {
        static let settingsNotification = "dict_settings_notification"
        static let settingsSound        = "dict_settings_sound"
        static let userProgress         = "dict_user_progress"
        static let ownedCardIDs         = "dict_owned_card_ids"
        static let proCachedActive      = "dict_pro_cached_active"
        static let proCachedCheckedAt   = "dict_pro_cached_checked_at"
        static let launchCount          = "dict_app_launch_count"
        static let reviewRequestedAt    = "dict_review_requested_at_count"
        static let debugAutoClear       = "dict_debug_auto_clear"
        static let debugNotificationTest = "dict_debug_notification_test"
    }

    // MARK: - IAP

    static let iapProductID = "jp.dictation.learning.pro"

    // MARK: - URLs

    static let reviewURL = "https://apps.apple.com/jp/app/id0000000000?action=write-review"
    static let shareURL  = "https://apps.apple.com/jp/app/id0000000000"
    static let aboutURL  = "http://ktwvai.sakura.ne.jp/app/dictation/"

    // MARK: - Notification

    static let notificationTitle     = "英語ディクテーション - 本日の練習"
    static let notificationTestTitle = "英語ディクテーション - 本日の練習（テスト）"
    static let notificationHour      = 7
    static let notificationMinute    = 59

    // MARK: - Gacha Display

    static let gachaTitle    = "ディクテーションガチャ"
    static let gachaSubtitle = "リスニングカードを獲得"
    static let gachaChallengeLabel = "ガチャに挑戦！"
    static let gachaDrawLabel      = "リスニングカードを"  // + "\(count)枚引く"
    static let gachaMinAccuracy    = 60  // ガチャ対象の最低正解率(%)

    // MARK: - Card

    static let cardAspectRatio: CGFloat = 900.0 / 1275.0

    // MARK: - Level Data Files

    static let levelFiles = [
        "level1",
        "level2",
        "level3",
    ]

    // MARK: - SubLevel Definitions

    /// サブレベル定義: トップメニューに表示するカテゴリ
    /// level=JSONのレベル名, setRange=含まれるセット番号の範囲
    struct SubLevelDef {
        let id: String           // "level1a", "level1b", etc.
        let sourceLevel: String  // "level1", "level2", "level3"
        let title: String        // "初級1", "初級2", etc.
        let setRange: ClosedRange<Int>  // セット番号の範囲
    }

    static let subLevels: [SubLevelDef] = [
        SubLevelDef(id: "level1a", sourceLevel: "level1", title: "初級1",  setRange: 1...34),
        SubLevelDef(id: "level1b", sourceLevel: "level1", title: "初級2",  setRange: 35...67),
        SubLevelDef(id: "level1c", sourceLevel: "level1", title: "初級3",  setRange: 68...100),
        SubLevelDef(id: "level2a", sourceLevel: "level2", title: "中級1",  setRange: 1...30),
        SubLevelDef(id: "level2b", sourceLevel: "level2", title: "中級2",  setRange: 31...60),
        SubLevelDef(id: "level3",  sourceLevel: "level3", title: "上級",   setRange: 1...40),
    ]

    // MARK: - Rank Labels & Result Comments

    struct RankInfo {
        let label: String
        let minPercent: Int
    }

    static let rankLabels: [RankInfo] = [
        RankInfo(label: "パーフェクト！", minPercent: 100),
        RankInfo(label: "よくできました",  minPercent: 80),
        RankInfo(label: "あと少し！",      minPercent: 60),
        RankInfo(label: "復習しましょう",   minPercent: 0),
    ]

    static func rankLabel(for percent: Int) -> String {
        rankLabels.first { percent >= $0.minPercent }?.label ?? "復習しましょう"
    }

    struct ExamComment {
        let message: String
        let minPercent: Int
        let isGood: Bool
    }

    static let examComments: [ExamComment] = [
        ExamComment(message: "素晴らしい結果です！\nリスニング力が着実に向上しています。",          minPercent: 80, isGood: true),
        ExamComment(message: "もう少しで完璧！\n苦手なパターンを復習しましょう。",              minPercent: 60, isGood: true),
        ExamComment(message: "基礎は押さえています。\n引き続き練習を続けましょう。",             minPercent: 40, isGood: false),
        ExamComment(message: "まだまだ伸びしろがあります。\n復習モードで基礎から固めましょう。",   minPercent: 0,  isGood: false),
    ]

    static func examComment(for percent: Int) -> ExamComment {
        examComments.first { percent >= $0.minPercent }
            ?? ExamComment(message: "復習しましょう", minPercent: 0, isGood: false)
    }

    // MARK: - Paywall

    static let paywallTitle    = "フルアクセスを解除"
    static let paywallSubtitle = "すべての機能を使って\nリスニング力を鍛えよう"

    static let paywallBenefits = [
        (icon: "headphones",                       text: "全レベル・全セットのディクテーション"),
        (icon: "doc.text.fill",                    text: "初級〜上級の実力テスト"),
        (icon: "photo.on.rectangle.angled",        text: "リスニングカードコレクション"),
    ]

    // MARK: - Data Notice

    static let dataNoticeTitle    = "データの保存に関するご注意"
    static let dataNoticeSubtitle = "リスニングカードのコレクションデータに関して"

    // MARK: - Dictation Specific

    /// 正答率のしきい値（90%以上で正解とみなす）
    static let correctnessThreshold: Double = 0.90

    /// ゆっくり再生速度
    static let slowPlaybackRate: Float = 0.7

    /// 通常再生速度
    static let normalPlaybackRate: Float = 1.0
}
