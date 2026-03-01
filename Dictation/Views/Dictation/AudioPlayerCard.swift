import SwiftUI

// MARK: - AudioPlayerCard

/// 音声再生コントロールカード
struct AudioPlayerCard: View {
    @ObservedObject var audioManager: AudioPlaybackManager
    let onPlay: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            // 再生ボタン
            Button(action: onPlay) {
                HStack(spacing: 10) {
                    Image(systemName: audioManager.isPlaying ? "speaker.wave.3.fill" : "play.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.white)
                        .symbolEffect(.variableColor.iterative, isActive: audioManager.isPlaying)

                    Text(audioManager.isPlaying ? "再生中..." : "音声を再生")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient.appTheme(AppColors.nextButtonGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                )
                .shadow(color: AppColors.primary.opacity(0.25), radius: 6, x: 0, y: 3)
            }
            .buttonStyle(.plain)

            // 速度切替 & 再生回数
            HStack {
                // 速度ボタン
                Button {
                    audioManager.toggleSpeed()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "tortoise.fill")
                            .font(.system(size: 14))
                        Text(audioManager.playbackRate == AppConfig.slowPlaybackRate ? "ゆっくり" : "通常速度")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundStyle(audioManager.playbackRate == AppConfig.slowPlaybackRate ? AppColors.primary : AppColors.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        (audioManager.playbackRate == AppConfig.slowPlaybackRate ? AppColors.primary : AppColors.gray)
                            .opacity(0.12)
                    )
                    .clipShape(Capsule())
                }

                Spacer()

                // 再生回数
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12))
                    Text("再生: \(audioManager.playCount)回")
                        .font(.system(size: 13))
                }
                .foregroundStyle(AppColors.textSecondary)
            }
        }
        .padding(16)
        .background(AppColors.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 4)
    }
}
