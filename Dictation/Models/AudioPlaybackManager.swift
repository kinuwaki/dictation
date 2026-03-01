import AVFoundation
import Combine

// MARK: - AudioPlaybackManager

/// ディクテーション音声の再生管理。
/// バンドルMP3がある場合はそれを再生、なければ AVSpeechSynthesizer でTTSフォールバック。
@MainActor
final class AudioPlaybackManager: NSObject, ObservableObject {

    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var duration: TimeInterval = 0
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var playCount: Int = 0
    @Published var playbackRate: Float = AppConfig.normalPlaybackRate

    private var audioPlayer: AVAudioPlayer?
    private var speechSynth: AVSpeechSynthesizer?
    private var timerCancellable: AnyCancellable?
    private var useTTS: Bool = false

    override init() {
        super.init()
        configureAudioSession()
    }

    // MARK: - Audio Session

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true)
        } catch {
            AppLogger.warning("[AudioPlayback] AudioSession設定エラー: \(error)")
        }
    }

    // MARK: - Load

    /// 音声ファイルをロード。バンドルになければTTSモードにフォールバック。
    func load(audioFile: String, text: String) {
        stop()
        useTTS = false
        playCount = 0

        // バンドルからMP3を探す
        let name = (audioFile as NSString).deletingPathExtension
        let ext = (audioFile as NSString).pathExtension.isEmpty ? "mp3" : (audioFile as NSString).pathExtension

        if let url = Bundle.main.url(forResource: name, withExtension: ext) {
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.enableRate = true
                player.delegate = self
                player.prepareToPlay()
                self.audioPlayer = player
                self.duration = player.duration
                AppLogger.debug("[AudioPlayback] ファイル読み込み成功: \(audioFile)")
                return
            } catch {
                AppLogger.warning("[AudioPlayback] ファイル再生準備エラー: \(error)")
            }
        }

        // フォールバック: TTS
        AppLogger.info("[AudioPlayback] TTSフォールバック: \(audioFile)")
        useTTS = true
        speechSynth = AVSpeechSynthesizer()
    }

    // MARK: - Playback Controls

    func play(text: String? = nil) {
        if useTTS {
            guard let text, let synth = speechSynth else { return }
            if synth.isSpeaking { synth.stopSpeaking(at: .immediate) }
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            utterance.rate = playbackRate == AppConfig.slowPlaybackRate
                ? AVSpeechUtteranceDefaultSpeechRate * 0.7
                : AVSpeechUtteranceDefaultSpeechRate
            utterance.pitchMultiplier = 1.0
            synth.speak(utterance)
            isPlaying = true
            playCount += 1

            // TTS終了を検知するためポーリング
            timerCancellable = Timer.publish(every: 0.2, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in
                    guard let self else { return }
                    if self.speechSynth?.isSpeaking != true {
                        self.isPlaying = false
                        self.timerCancellable?.cancel()
                    }
                }
        } else {
            guard let player = audioPlayer else { return }
            player.rate = playbackRate
            player.currentTime = 0
            player.play()
            isPlaying = true
            playCount += 1
            startTimeTracking()
        }
    }

    func stop() {
        audioPlayer?.stop()
        speechSynth?.stopSpeaking(at: .immediate)
        isPlaying = false
        currentTime = 0
        timerCancellable?.cancel()
    }

    func toggleSpeed() {
        if playbackRate == AppConfig.normalPlaybackRate {
            playbackRate = AppConfig.slowPlaybackRate
        } else {
            playbackRate = AppConfig.normalPlaybackRate
        }
    }

    // MARK: - Time Tracking

    private func startTimeTracking() {
        timerCancellable = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, let player = self.audioPlayer else { return }
                self.currentTime = player.currentTime
                if !player.isPlaying {
                    self.isPlaying = false
                    self.timerCancellable?.cancel()
                }
            }
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioPlaybackManager: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isPlaying = false
            self.timerCancellable?.cancel()
        }
    }
}
