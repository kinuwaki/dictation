import AVFoundation

// MARK: - SoundManager

/// 効果音の一元管理。効果音設定が OFF のときは再生しない。
final class SoundManager {
    static let shared = SoundManager()
    private init() {}

    private var player: AVAudioPlayer?

    enum Sound: String {
        case correct = "pinpon"
        case wrong   = "buzzer"
        case gacha   = "gacha"
    }

    func play(_ sound: Sound) {
        guard UserDefaults.standard.object(forKey: AppConfig.Keys.settingsSound) as? Bool ?? true else { return }

        guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "mp3") else {
            AppLogger.warning("[SoundManager] \(sound.rawValue).mp3 が見つかりません")
            return
        }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.play()
        } catch {
            AppLogger.warning("[SoundManager] 再生エラー: \(error)")
        }
    }
}
