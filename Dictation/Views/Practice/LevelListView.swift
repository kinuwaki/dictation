import SwiftUI

// MARK: - LevelListView

struct LevelListView: View {
    let allItems: [DictationItem]

    @EnvironmentObject var progressStore: UserProgressStore

    private var levels: [Level] {
        Level.allLevels()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // タイトル
                VStack(spacing: 4) {
                    Text("ディクテーション")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                    Text("レベルを選んで開始")
                        .font(.system(size: 14))
                        .foregroundStyle(AppColors.textSecondary)
                }
                .padding(.top, 12)

                Spacer().frame(height: 16)

                // レベル選択カード
                VStack(spacing: 12) {
                    ForEach(Array(levels.enumerated()), id: \.element.id) { index, level in
                        NavigationLink(value: LevelDestination(level: level)) {
                            ThemeButton(
                                iconName: level.iconName,
                                title: level.displayTitle,
                                subtitle: Self.subtitle(level: level, progress: progressStore),
                                gradientColors: Level.gradientColors(for: index)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(14)
                .background(AppColors.cardSurface)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 3)
                .padding(.horizontal, 16)

                Spacer().frame(height: 80)
            }
        }
        .background(AppColors.background)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    static func subtitle(level: Level, progress: UserProgressStore) -> String {
        let totalSets = level.totalSetCount
        let completedSets = level.setRange.filter { setIndex in
            let key = UserProgress.setKey(level: level.sourceLevel, setIndex: setIndex)
            return progress.progress.completedSets.contains(key)
        }.count
        return "\(completedSets) / \(totalSets) セット完了"
    }
}
